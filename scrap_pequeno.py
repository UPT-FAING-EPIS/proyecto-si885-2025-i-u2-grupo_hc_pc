# filepath: c:\Users\angel\Documents\IN\scarp\Scrap\scrap_pequeno.py
import requests
import pandas as pd
from collections import defaultdict
from bs4 import BeautifulSoup
import time
import re
from datetime import datetime
import os
import sqlalchemy
from sqlalchemy import create_engine
import urllib

# Configuración
ORG_NAME = "UPT-FAING-EPIS"
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
HEADERS = {
    "Authorization": f"token {GITHUB_TOKEN}",
    "Accept": "application/vnd.github.v3+json"
}
REQUEST_TIMEOUT = 15

def get_db_engine():
    """Crea y retorna un engine de SQLAlchemy para la base de datos Azure SQL."""
    db_server = os.getenv("DB_SERVER")
    db_database = os.getenv("DB_DATABASE")
    db_username = os.getenv("DB_USERNAME")
    db_password = os.getenv("DB_PASSWORD")
    
    if not all([db_server, db_database, db_username, db_password, GITHUB_TOKEN]):
        raise ValueError("Una o más variables de entorno requeridas no están configuradas (GITHUB_TOKEN, DB_SERVER, DB_DATABASE, DB_USERNAME, DB_PASSWORD)")

    driver = '{ODBC Driver 18 for SQL Server}'
    params = urllib.parse.quote_plus(
        f"DRIVER={driver};"
        f"SERVER=tcp:{db_server},1433;"
        f"DATABASE={db_database};"
        f"UID={db_username};"
        f"PWD={db_password};"
        f"Encrypt=yes;"
        f"TrustServerCertificate=no;"
        "Connection Timeout=30;"
    )
    
    conn_str = f"mssql+pyodbc:///?odbc_connect={params}"
    engine = create_engine(conn_str, fast_executemany=True)
    return engine

def clear_database_tables(engine):
    """Elimina todos los datos de las tablas en el orden correcto para evitar problemas de FK."""
    tables_to_clear = [
        "ProyectoCICD", "ProyectoBasesDeDatos", "ProyectoLibrerias", "ProyectoFrameworks",
        "Commits", "Issues", "ColaboradoresPorProyecto", "Proyectos", "Usuarios", "Cursos"
    ]
    with engine.connect() as connection:
        transaction = connection.begin()
        try:
            # Deshabilitar constraints para TRUNCATE
            for table in tables_to_clear:
                connection.execute(sqlalchemy.text(f'ALTER TABLE {table} NOCHECK CONSTRAINT ALL'))
            
            for table in tables_to_clear:
                print(f"Limpiando tabla {table}...")
                connection.execute(sqlalchemy.text(f'TRUNCATE TABLE {table}'))

            # Habilitar constraints de nuevo
            for table in tables_to_clear:
                connection.execute(sqlalchemy.text(f'ALTER TABLE {table} WITH CHECK CHECK CONSTRAINT ALL'))

            transaction.commit()
            print("Todas las tablas han sido limpiadas exitosamente.")
        except Exception as e:
            print(f"Error durante la limpieza de tablas: {e}")
            transaction.rollback()
            raise

def get_entity_keys(table_name, row):
    """Genera PartitionKey y RowKey para una fila de un DataFrame, asegurando que sean strings y válidos."""
    if table_name == "Cursos":
        pk = str(row.get("NombreCurso", "default_curso"))
        rk = str(row.get("CursoID", "default_id"))
    elif table_name == "Usuarios":
        pk = str(row.get("TipoUsuario", "default_tipo"))
        rk = str(row.get("UsuarioID", "default_id"))
    elif table_name == "Proyectos":
        pk = str(row.get("CursoID", "default_curso"))
        rk = str(row.get("ProyectoID", "default_id"))
    elif table_name == "ColaboradoresPorProyecto":
        pk = str(row.get("ProyectoID"))
        rk = str(row.get("UsuarioID"))
    elif table_name == "Issues":
        pk = str(row.get("ProyectoID"))
        rk = str(row.get("IssueID"))
    elif table_name == "Commits":
        pk = str(row.get("ProyectoID"))
        rk = str(row.get("CommitSHA"))
    elif table_name == "ProyectoFrameworks":
        pk = str(row.get("ProyectoID"))
        rk = str(row.get("Framework"))
    elif table_name == "ProyectoLibrerias":
        pk = str(row.get("ProyectoID"))
        rk = f'{row.get("Libreria")}_{row.get("LenguajeContexto")}'

    elif table_name == "ProyectoBasesDeDatos":
        pk = str(row.get("ProyectoID"))
        rk = str(row.get("BaseDeDatos"))
    elif table_name == "ProyectoCICD":
        pk = str(row.get("ProyectoID"))
        rk = str(row.get("HerramientaCI_CD"))
    else:
        pk = "default_partition"
        rk = str(row.name)
    
    invalid_chars = r'[\#\?\/]'
    pk = re.sub(invalid_chars, '-', pk)
    rk = re.sub(invalid_chars, '-', rk)
    
    return pk, rk

def load_data_to_db(engine, data_frames):
    """Carga los DataFrames en la base de datos en el orden correcto."""
    load_order = [
        ("Cursos", data_frames["cursos"]),
        ("Usuarios", data_frames["usuarios"]),
        ("Proyectos", data_frames["proyectos"]),
        ("ColaboradoresPorProyecto", data_frames["colaboradores_proyecto"]),
        ("Issues", data_frames["issues"]),
        ("Commits", data_frames["commits"]),
        ("ProyectoFrameworks", data_frames["proyecto_frameworks"]),
        ("ProyectoLibrerias", data_frames["proyecto_librerias"]),
        ("ProyectoBasesDeDatos", data_frames["proyecto_db"]),
        ("ProyectoCICD", data_frames["proyecto_cicd"]),
    ]

    with engine.connect() as connection:
        for name, df in load_order:
            if df.empty:
                print(f"DataFrame para la tabla {name} está vacío. Omitiendo carga.")
                continue
            print(f"Cargando {len(df)} filas en la tabla {name}...")
            try:
                df.to_sql(name, con=connection, if_exists='append', index=False, chunksize=200)
                print(f"  Carga para {name} completada.")
            except Exception as e:
                print(f"Error al cargar datos en la tabla {name}: {e}")
                raise

def get_paginated_data(url, params=None, max_retries=3, backoff_factor=0.3):
    """Obtener datos paginados de la API de GitHub con reintentos."""
    items = []
    page = 1
    retries = 0
    while True:
        paginated_url = f"{url}?page={page}&per_page=100"
        if params:
            paginated_url += "&" + "&".join([f"{k}={v}" for k, v in params.items()])
        
        try:
            response = requests.get(paginated_url, headers=HEADERS, timeout=REQUEST_TIMEOUT)
            response.raise_for_status() # Lanza HTTPError para respuestas 4XX/5XX
            
            data = response.json()
            if not data:
                break
                
            items.extend(data)
            page += 1
            retries = 0 # Reset reintentos si la petición es exitosa

            if 'Link' not in response.headers or 'rel="next"' not in response.headers['Link']:
                 break # No hay más páginas
            time.sleep(0.5) # Pequeña pausa entre páginas

        except requests.exceptions.RequestException as e:
            retries += 1
            if retries > max_retries:
                print(f"Error final al obtener datos de {paginated_url} tras {max_retries} reintentos: {e}")
                break 
            wait_time = backoff_factor * (2 ** (retries - 1))
            print(f"Error al obtener datos de {paginated_url}: {e}. Reintentando en {wait_time:.2f} segundos... (Intento {retries}/{max_retries})")
            time.sleep(wait_time)
        
    return items

def get_all_repos(org_name):
    """Obtener todos los repositorios de una organización"""
    url = f"https://api.github.com/orgs/{org_name}/repos"
    return get_paginated_data(url)

def analyze_repo_languages(repo, max_retries=3, backoff_factor=0.3):
    """Analizar los lenguajes de un repositorio con reintentos."""
    url = repo['languages_url']
    retries = 0
    while retries <= max_retries:
        try:
            response = requests.get(url, headers=HEADERS, timeout=REQUEST_TIMEOUT)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            retries += 1
            if retries > max_retries:
                print(f"Error final al obtener lenguajes de {url} tras {max_retries} reintentos: {e}")
                return {} # Retornar vacío si todos los reintentos fallan
            wait_time = backoff_factor * (2 ** (retries - 1))
            print(f"Error al obtener lenguajes de {url}: {e}. Reintentando en {wait_time:.2f} segundos... (Intento {retries}/{max_retries})")
            time.sleep(wait_time)
    return {} # En caso de que el bucle termine inesperadamente

def get_repo_readme(repo, max_retries=3, backoff_factor=0.3):
    """Obtener el contenido del README de un repositorio con reintentos."""
    url = f"https://api.github.com/repos/{repo['full_name']}/readme"
    retries = 0
    readme_content = "" # Valor por defecto

    while retries <= max_retries:
        try:
            response = requests.get(url, headers=HEADERS, timeout=REQUEST_TIMEOUT)
            response.raise_for_status()
            readme_data = response.json()
            
            download_url = readme_data.get('download_url')
            if download_url:
                readme_response = requests.get(download_url, timeout=REQUEST_TIMEOUT)
                readme_response.raise_for_status()
                readme_content = readme_response.text.lower()
            break 
        except requests.exceptions.RequestException as e:
            retries += 1
            if retries > max_retries:
                print(f"Error final al obtener README de {repo['full_name']} tras {max_retries} reintentos: {e}")
                break 
            wait_time = backoff_factor * (2 ** (retries - 1))
            print(f"Error al obtener README de {repo['full_name']}: {e}. Reintentando en {wait_time:.2f} segundos... (Intento {retries}/{max_retries})")
            time.sleep(wait_time)
            if retries > max_retries and not readme_content: 
                 print(f"No se pudo obtener el README para {repo['full_name']}. Se devolverá una cadena vacía.")
    return readme_content

def detect_tech_in_readme(readme_content, tech_list):
    """Detectar tecnologías mencionadas en el README"""
    detected = []
    if not readme_content: 
        return detected
    for tech in tech_list:
        if re.search(r'\b' + re.escape(tech.lower()) + r'\b', readme_content):
            detected.append(tech)
    return detected

def get_repo_collaborators(repo_full_name):
    """Obtener colaboradores de un repositorio."""
    url = f"https://api.github.com/repos/{repo_full_name}/collaborators"
    return get_paginated_data(url)

def get_repo_issues(repo_full_name):
    """Obtener issues de un repositorio (abiertos y cerrados)."""
    url = f"https://api.github.com/repos/{repo_full_name}/issues"
    return get_paginated_data(url, params={"state": "all"})

def get_repo_commits(repo_full_name):
    """Obtener commits de un repositorio."""
    url = f"https://api.github.com/repos/{repo_full_name}/commits"
    return get_paginated_data(url)

def extract_course_info(repo_name):
    """Extraer información del curso y unidad del nombre del repositorio."""
    match = re.search(r'(si[a-zA-Z0-9]+).*?(u\d+)', repo_name.lower())
    if match:
        return match.group(1), match.group(2)
    match_simple_curso = re.search(r'(si[a-zA-Z0-9]+)', repo_name.lower())
    match_simple_unidad = re.search(r'(u\d+)', repo_name.lower())
    curso = match_simple_curso.group(1) if match_simple_curso else None
    unidad = match_simple_unidad.group(1) if match_simple_unidad else None
    if curso or unidad:
        return curso, unidad
    return None, None

def analyze_repositories_detailed_and_tech(repos):
    """
    Analizar todos los repositorios para extraer información detallada (relacional)
    y estadísticas tecnológicas (lenguajes, frameworks, etc.).
    """
    
    cursos_data = []
    proyectos_data = []
    usuarios_data = []
    colaboradores_proyecto_data = []
    issues_data = []
    commits_data = []

    proyecto_frameworks_data = []
    proyecto_librerias_data = []
    proyecto_db_data = []
    proyecto_cicd_data = []
    
    language_stats = defaultdict(int)
    language_project_counts = defaultdict(int) 
    framework_stats = defaultdict(int)
    library_stats = defaultdict(int) 
    db_stats = defaultdict(int)
    ci_cd_stats = defaultdict(int)
    # last_updated_dates = # Ya no se necesita

    language_type_map = {
        'JavaScript': 'Frontend/Fullstack', 'HTML': 'Frontend', 'CSS': 'Frontend',
        'Python': 'Backend/Fullstack', 'Java': 'Backend/Fullstack', 'C#': 'Backend/Fullstack',
        'PHP': 'Backend/Fullstack', 'Ruby': 'Backend/Fullstack', 'Go': 'Backend',
        'TypeScript': 'Frontend/Fullstack', 'Swift': 'Mobile', 'Kotlin': 'Mobile/Backend',
        'C++': 'System/Backend', 'C': 'System', 'Shell': 'Scripting/DevOps',
        'Objective-C': 'Mobile', 'Scala': 'Backend/Fullstack', 'R': 'Data Science',
        'PowerShell': 'Scripting/DevOps', 'Perl': 'Scripting/Backend', 'Lua': 'Scripting/GameDev',
        'Rust': 'System/Backend', 'Dart': 'Mobile/Frontend', 'Assembly': 'Low-level',
    }

    seen_cursos = set()
    seen_usuarios = set()
    seen_project_participants = set()

    frameworks_list = ["react", "angular", "vue", "django", "flask", "spring", "laravel", 
                       "express", "rails", ".net", "flutter", "xamarin", "asp.net", "ktor",
                       "next.js", "nestjs", "fastapi", "rubyonrails", "symfony"]
    
    libraries_map = { 
        'python': ["pandas", "numpy", "tensorflow", "pytorch", "scikit-learn", "matplotlib", 
                   "seaborn", "requests", "beautifulsoup", "scrapy", "opencv", "pillow",
                   "sqlalchemy", "pytest", "pygame", "nltk", "spacy", "transformers", "keras", 
                   "plotly", "bokeh", "dash", "celery"],
        'javascript': ["axios", "lodash", "moment", "jquery", "redux", "jest", "mocha", "chai", 
                       "webpack", "babel", "three.js", "d3.js", "socket.io", "mongoose", "sequelize",
                       "express", "react", "vue", "angular"], 
        'java': ["junit", "mockito", "lombok", "log4j", "slf4j", "gson", "jackson",
                 "hibernate", "spring-boot", "spring-mvc", "spring-security", "jpa",
                 "jdbc", "apache-commons", "guava", "assertj", "jersey", "vertx"],
        'c#': ["entityframework", "dapper", "newtonsoft.json", "nunit", "xunit",
               "moq", "serilog", "automapper", "mediatr", "polly", "hangfire",
               "signalr", "aspnetcore", "efcore", "identityserver", "fluentvalidation"],
        'php': ["phpunit", "monolog", "guzzle", "doctrine", "eloquent", "phpmailer", "twig", "composer"],
        'ruby': ["rspec", "capybara", "devise", "sidekiq", "puma", "faraday", "rubocop"],
        'go': ["gin", "echo", "gorm", "testify", "viper", "cobra", "zerolog", "uuid", "go-redis", "grpc-go", "mux"],
        'typescript': ["jest", "webpack", "babel", "express", "react", "vue", "angular", "rxjs", "typeorm"]
    }
    
    databases_list = ["mysql", "postgresql", "mongodb", "sqlite", "mariadb", "redis", 
                      "firebase", "oracle", "sqlserver", "cassandra", "dynamodb", "neo4j",
                      "elasticsearch", "couchdb", "rethinkdb", "arangodb", "cosmosdb", "supabase"]
    
    ci_cd_tools_list = ["github actions", "jenkins", "travis ci", "circleci", "gitlab ci", 
                        "azure pipelines", "teamcity", "bamboo", "bitbucket pipelines",
                        "argo cd", "tekton", "spinnaker", "flux", "docker", "kubernetes", "ansible", "terraform"]

    for repo in repos:
        print(f"\\\\nAnalizando repositorio: {repo['name']} (ID: {repo['id']})")
        
        repo_full_name = repo['full_name']
        repo_id = repo['id'] 
        
        curso_nombre_raw, unidad_raw = extract_course_info(repo['name'])
        curso_id = None
        if curso_nombre_raw:
            curso_key = (curso_nombre_raw, unidad_raw if unidad_raw else "N/A")
            if curso_key not in seen_cursos:
                cursos_data.append({
                    "CursoID": f"{curso_nombre_raw}_{unidad_raw if unidad_raw else 'NA'}",
                    "NombreCurso": curso_nombre_raw,
                    "Unidad": unidad_raw if unidad_raw else "N/A"
                })
                seen_cursos.add(curso_key)
            curso_id = f"{curso_nombre_raw}_{unidad_raw if unidad_raw else 'NA'}"

        proyectos_data.append({
            "ProyectoID": repo_id, "NombreProyecto": repo['name'], "RepoFullName": repo_full_name,
            "CursoID": curso_id, "Descripcion": repo['description'], "URLRepositorio": repo['html_url'],
            "FechaCreacion": repo['created_at'], "FechaUltimaActualizacion": repo['updated_at'],
            "LenguajePrincipal": repo.get('language', 'N/A'), "Stars": repo.get('stargazers_count', 0),
            "Forks": repo.get('forks_count', 0), "OpenIssues": repo.get('open_issues_count', 0),
            "FechaUltimaActividad": None # Se llenará más adelante
        })
        
        print(f"  Obteniendo issues para {repo_full_name}...")
        issues = get_repo_issues(repo_full_name)
        for issue in issues:
            creador_id = issue['user']['login'] if issue.get('user') else 'N/A'
            asignado_id = issue['assignee']['login'] if issue.get('assignee') else 'N/A'
            
            if creador_id != 'N/A' and creador_id not in seen_usuarios:
                 usuarios_data.append({"UsuarioID": creador_id, "NombreUsuario": creador_id, "URLPerfil": issue['user']['html_url'] if issue.get('user') else 'N/A', "TipoUsuario": issue['user']['type'] if issue.get('user') else 'N/A'})
                 seen_usuarios.add(creador_id)
            if creador_id != 'N/A' and (repo_id, creador_id) not in seen_project_participants:
                colaboradores_proyecto_data.append({"ProyectoID": repo_id, "UsuarioID": creador_id})
                seen_project_participants.add((repo_id, creador_id))

            if asignado_id != 'N/A' and asignado_id not in seen_usuarios:
                 usuarios_data.append({"UsuarioID": asignado_id, "NombreUsuario": asignado_id, "URLPerfil": issue['assignee']['html_url'] if issue.get('assignee') else 'N/A', "TipoUsuario": issue['assignee']['type'] if issue.get('assignee') else 'N/A'})
                 seen_usuarios.add(asignado_id)
            if asignado_id != 'N/A' and (repo_id, asignado_id) not in seen_project_participants:
                colaboradores_proyecto_data.append({"ProyectoID": repo_id, "UsuarioID": asignado_id})
                seen_project_participants.add((repo_id, asignado_id))
            
            issues_data.append({
                "IssueID": issue['id'], "ProyectoID": repo_id, "NumeroIssue": issue['number'],
                "Titulo": issue['title'], "Estado": issue['state'], "CreadorID": creador_id,
                "AsignadoID": asignado_id, "FechaCreacion": issue['created_at'],
                "FechaActualizacion": issue['updated_at'], "FechaCierre": issue.get('closed_at'),
                "URLIssue": issue['html_url'], "Comentarios": issue.get('comments', 0)
            })
        time.sleep(0.25)

        print(f"  Obteniendo commits para {repo_full_name}...")
        commits_list = get_repo_commits(repo_full_name)
        for commit_info in commits_list:
            autor_login = commit_info['author']['login'] if commit_info.get('author') else 'N/A'
            committer_login = commit_info['committer']['login'] if commit_info.get('committer') else 'N/A'
            
            if autor_login != 'N/A' and autor_login not in seen_usuarios:
                 usuarios_data.append({"UsuarioID": autor_login, "NombreUsuario": autor_login, "URLPerfil": commit_info['author']['html_url'] if commit_info.get('author') else 'N/A', "TipoUsuario": commit_info['author']['type'] if commit_info.get('author') else 'N/A'})
                 seen_usuarios.add(autor_login)
            if autor_login != 'N/A' and (repo_id, autor_login) not in seen_project_participants:
                colaboradores_proyecto_data.append({"ProyectoID": repo_id, "UsuarioID": autor_login})
                seen_project_participants.add((repo_id, autor_login))

            if committer_login != 'N/A' and committer_login not in seen_usuarios and committer_login != autor_login:
                 usuarios_data.append({"UsuarioID": committer_login, "NombreUsuario": committer_login, "URLPerfil": commit_info['committer']['html_url'] if commit_info.get('committer') else 'N/A', "TipoUsuario": commit_info['committer']['type'] if commit_info.get('committer') else 'N/A'})
                 seen_usuarios.add(committer_login)
            if committer_login != 'N/A' and committer_login != autor_login and (repo_id, committer_login) not in seen_project_participants:
                colaboradores_proyecto_data.append({"ProyectoID": repo_id, "UsuarioID": committer_login})
                seen_project_participants.add((repo_id, committer_login))
            
            commits_data.append({
                "CommitSHA": commit_info['sha'], "ProyectoID": repo_id, "AutorID": autor_login,
                "CommitterID": committer_login, "Mensaje": commit_info['commit']['message'],
                "FechaCommit": commit_info['commit']['author']['date'], "URLCommit": commit_info['html_url']
            })
        time.sleep(0.25)
        
        print(f"  Analizando tecnologías para {repo_full_name}...")
        repo_langs = analyze_repo_languages(repo) 
        for lang, bytes_count in repo_langs.items():
            language_stats[lang] += bytes_count
            language_project_counts[lang] += 1 
        
        readme_content = get_repo_readme(repo) 
        
        for framework in detect_tech_in_readme(readme_content, frameworks_list):
            framework_stats[framework] += 1
            proyecto_frameworks_data.append({"ProyectoID": repo_id, "Framework": framework})
            
        detected_repo_langs_lower = [l.lower() for l in repo_langs.keys()]
        all_possible_libraries = []
        for lang_key, libs in libraries_map.items():
            if lang_key in detected_repo_langs_lower: 
                 all_possible_libraries.extend(libs)

        unique_libraries_to_search = list(set(all_possible_libraries))

        for library in detect_tech_in_readme(readme_content, unique_libraries_to_search):
            prefix = "general" 
            for lang_map_key, libs_in_map in libraries_map.items(): 
                if library.lower() in [l.lower() for l in libs_in_map]:
                    prefix = lang_map_key
                    break 
            library_stats[f"{prefix}:{library.lower()}"] += 1
            proyecto_librerias_data.append({"ProyectoID": repo_id, "Libreria": library.lower(), "LenguajeContexto": prefix})

        for db in detect_tech_in_readme(readme_content, databases_list):
            db_stats[db] += 1
            proyecto_db_data.append({"ProyectoID": repo_id, "BaseDeDatos": db})

        for ci_cd_tool in detect_tech_in_readme(readme_content, ci_cd_tools_list):
            ci_cd_stats[ci_cd_tool] += 1
            proyecto_cicd_data.append({"ProyectoID": repo_id, "HerramientaCI_CD": ci_cd_tool})

        repo_specific_commits = [
            datetime.strptime(commit['FechaCommit'], "%Y-%m-%dT%H:%M:%SZ")
            for commit in commits_data 
            if commit['ProyectoID'] == repo_id and commit.get('FechaCommit') 
        ]
        last_activity_date_str = None
        if repo_specific_commits:
            last_commit_date_dt = max(repo_specific_commits)
            last_activity_date_str = last_commit_date_dt.strftime("%Y-%m-%d %H:%M:%S")
        else:
            updated_at_dt = datetime.strptime(repo['updated_at'], "%Y-%m-%dT%H:%M:%SZ")
            last_activity_date_str = updated_at_dt.strftime("%Y-%m-%d %H:%M:%S")
        
        proyectos_data[-1]["FechaUltimaActividad"] = last_activity_date_str
        
        time.sleep(1) 

    df_cursos = pd.DataFrame(cursos_data)
    df_proyectos = pd.DataFrame(proyectos_data)
    df_usuarios = pd.DataFrame(usuarios_data)
    df_colaboradores_proyecto = pd.DataFrame(colaboradores_proyecto_data)
    df_issues = pd.DataFrame(issues_data)
    df_commits = pd.DataFrame(commits_data)
    
    df_proyecto_frameworks = pd.DataFrame(proyecto_frameworks_data)
    df_proyecto_librerias = pd.DataFrame(proyecto_librerias_data)
    df_proyecto_db = pd.DataFrame(proyecto_db_data)
    df_proyecto_cicd = pd.DataFrame(proyecto_cicd_data)

    # Se eliminan los dataframes de estadísticas y la escritura a Excel
    
    return {
        "cursos": df_cursos,
        "proyectos": df_proyectos,
        "usuarios": df_usuarios,
        "colaboradores_proyecto": df_colaboradores_proyecto,
        "issues": df_issues,
        "commits": df_commits,
        "proyecto_frameworks": df_proyecto_frameworks,
        "proyecto_librerias": df_proyecto_librerias,
        "proyecto_db": df_proyecto_db,
        "proyecto_cicd": df_proyecto_cicd,
    }

if __name__ == '__main__':
    # --- Ejecución del análisis para un subconjunto de repositorios ---
    all_repos = get_all_repos(ORG_NAME)
    print(f"Total de repositorios encontrados en la organización: {len(all_repos)}")
    
    # Limitar a los primeros 30 repositorios para la versión pequeña
    repos_to_analyze = all_repos[:600] 
    print(f"Analizando los primeros {len(repos_to_analyze)} repositorios de {len(all_repos)}.")
    
    if repos_to_analyze:
        data_frames = analyze_repositories_detailed_and_tech(repos_to_analyze)
        try:
            db_engine = get_db_engine()
            print("Conexión a la base de datos establecida.")
            
            print("Limpiando la base de datos...")
            clear_database_tables(db_engine)
            
            print("Cargando nuevos datos a la base de datos...")
            load_data_to_db(db_engine, data_frames)
            
            print("Proceso ETL completado exitosamente.")
        except Exception as e:
            print(f"Ocurrió un error durante el proceso ETL: {e}")
    else:
        print("No hay repositorios para analizar después de aplicar el límite.")

# --- Notas ---
# 1. Asegúrate de tener los permisos necesarios en tu token de GitHub.
# 2. El script ahora depende de la variable de entorno STORAGE_CONNECTION_STRING.
# 3. Las tablas en Azure se crearán automáticamente si no existen.
# 4. El workflow de GitHub Actions se encargará de la ejecución periódica.
