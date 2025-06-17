[![Open in Codespaces](https://classroom.github.com/assets/launch-codespace-2972f46106e565e64193e422d61a12cf1da4916b45550586e14ef0a7c637dd04.svg)](https://classroom.github.com/open-in-codespaces?assignment_repo_id=18703737)
# Proyecto: Análisis del Uso de Herramientas Tecnológicas en los Proyectos de Estudiantes de Sistemas UPT

## Universidad Privada de Tacna
**Facultad de Ingeniería**  
**Escuela Profesional de Ingeniería de Sistemas**  

### Curso: Inteligencia de Negocios

**Docente:** Mag. Patrick Cuadros Quiroga

### Integrantes:
- **Hernandez Cruz, Angel Gadiel** (2021070017)  
- **Paja de la Cruz, Piero Alexander** (2020067576)  
### RoadMap:
![./media/media/Roadmap.png](./media/Roadmap.png)


## Funcionalidades Principales

-   **Automatización Completa del Proceso ETL**: El pipeline se ejecuta de forma automática, sin intervención manual, en cada cambio del código o de forma programada.
-   **Aprovisionamiento Dinámico de Infraestructura**: Utiliza Terraform para crear y configurar todos los recursos necesarios en Azure desde cero en cada ejecución, garantizando un entorno limpio y reproducible.
-   **Extracción de Datos de GitHub**: Se conecta a la API de GitHub para recopilar una amplia gama de datos: metadatos del repositorio, commits, issues, colaboradores y lenguajes de programación.
-   **Análisis de Tecnologías**: Analiza el contenido de los archivos `README.md` para detectar el uso de frameworks, librerías, bases de datos y herramientas de CI/CD.
-   **Almacenamiento Estructurado**: Carga los datos procesados en una base de datos relacional en Azure SQL, listos para ser consumidos por herramientas de BI.

## Requerimientos Funcionales

| ID    | Requerimiento                                                                                             |
|-------|-----------------------------------------------------------------------------------------------------------|
| RF-01 | El sistema debe poder extraer datos de los repositorios de la organización `UPT-FAING-EPIS` en GitHub.      |
| RF-02 | El sistema debe identificar y cuantificar los lenguajes de programación utilizados en cada proyecto.       |
| RF-03 | El sistema debe detectar el uso de frameworks, librerías y bases de datos a partir del `README.md`.        |
| RF-04 | El sistema debe almacenar los datos extraídos y procesados en una base de datos Azure SQL.                |
| RF-05 | El proceso ETL completo debe ser automatizado y poder ejecutarse de forma programada (semanalmente).      |
| RF-06 | La infraestructura en la nube debe crearse y configurarse automáticamente.                                |

## Diagramas en Mermaid

### Diagrama de Arquitectura

```mermaid
graph TD
    A[Usuario/Desarrollador] -- Push a 'main' --> B{GitHub};
    C[Scheduler] -- Lunes 3 AM UTC --> B;
    B -- Activa --> D[Pipeline en GitHub Actions];
    D -- 1. Job: terraform-deploy --> E{Terraform};
    E -- Aprovisiona --> F[Azure Resource Group];
    F --> G[Azure SQL Server];
    G --> H[Azure SQL Database];
    H -- Credenciales --> D;
    D -- 2. Job: run-etl --> I[Script Python];
    I -- Lee schema.sql --> H;
    I -- Llama a --> J[GitHub API];
    J -- Devuelve datos --> I;
    I -- Procesa con Pandas --> I;
    I -- Carga datos --> H;
    K[Analista de BI] -- Consume datos --> L[Power BI];
    H -- Provee datos --> L;
```

### Diagrama de Casos de Uso

```mermaid
graph TD
    subgraph "Sistema de Análisis Tecnológico"
        UC1(Ejecutar Pipeline ETL)
        UC2(Extraer Datos de Proyectos)
        UC3(Analizar Tecnologías)
        UC4(Almacenar Datos Procesados)
    end

    actor "Desarrollador" as Dev
    actor "Analista de BI" as Analyst
    actor "Scheduler" as Clock

    Dev -- Activa --> UC1
    Clock -- Activa --> UC1
    UC1 -- include --> UC2
    UC2 -- include --> UC3
    UC3 -- include --> UC4
    Analyst --|> User
    Dev --|> User
    UC4 -- Permite --> (Generar Reportes de BI)
    Analyst -->(Generar Reportes de BI)
```

### Diagrama de Secuencia

#### RF01 - Extracción de metadatos
```mermaid
sequenceDiagram
    participant Sistema
    participant GitHubAPI
    participant BD
    
    Sistema->>GitHubAPI: GET /repos (con token)
    GitHubAPI-->>Sistema: JSON con metadatos
    Sistema->>BD: INSERT metadatos_proyecto
    BD-->>Sistema: Confirmación
    Sistema->>Sistema: Log de auditoría
```
#### RF02 - Clasificación de lenguajes 
```mermaid
sequenceDiagram
    participant Sistema
    participant Repositorio
    participant Clasificador
    
    Sistema->>Repositorio: Obtener archivos clave
    Repositorio-->>Sistema: Archivos .gitignore, manifestos
    Sistema->>Clasificador: Analizar contenido
    Clasificador-->>Sistema: Lenguaje principal + tecnologías
    Sistema->>BD: UPDATE proyecto SET tecnologías
```
#### RF03 - Generación de reportes
```mermaid
sequenceDiagram
    actor Usuario
    participant Frontend
    participant Backend
    participant BD
    
    Usuario->>Frontend: Solicitar reporte (rango fechas)
    Frontend->>Backend: GET /reportes?fechaInicio=X&fechaFin=Y
    Backend->>BD: Query agregada tecnologías
    BD-->>Backend: Dataset estadístico
    Backend->>Backend: Generar visualizaciones
    Backend-->>Frontend: JSON con datos + gráficos
    Frontend->>Usuario: Mostrar dashboard interactivo
```

## Reglas de Negocio

-   **Activación del Pipeline**: El pipeline se ejecuta con cada `push` a la rama `main` y de forma programada todos los lunes a las 3:00 AM UTC.
-   **Infraestructura Efímera**: La infraestructura en Azure (servidor y base de datos) se crea desde cero en cada ejecución del pipeline y no se destruye automáticamente. Esto garantiza un entorno limpio para cada carga, pero requiere una limpieza manual posterior si se desea controlar costos.
-   **Alcance del Análisis**: El script está configurado para analizar los primeros 50 repositorios (`scrap_pequeno.py`).
-   **Identificación de Cursos**: La asignación de un proyecto a un curso se basa en la detección de patrones como `si...` y `u...` en el nombre del repositorio. Si no se encuentra el patrón, el curso no se asigna.
-   **Detección de Tecnologías**: La identificación de frameworks, librerías, bases de datos y herramientas de CI/CD depende exclusivamente de su mención explícita en el archivo `README.md` del repositorio.

## Recomendaciones

-   **Estandarizar Nomenclatura**: Fomentar el uso de una convención de nombres estandarizada para los repositorios para mejorar la precisión en la identificación de cursos y unidades.
-   **Documentación en READMEs**: Incentivar a los estudiantes a documentar las tecnologías utilizadas en el `README.md` de sus proyectos para enriquecer los datos recopilados.
-   **Optimización de Costos**: Considerar añadir un paso de `terraform destroy` al final del pipeline o un pipeline separado para la limpieza de recursos en Azure y así evitar costos inesperados.
-   **Seguridad de Credenciales**: Las credenciales `AZURE_CREDENTIALS` y `GITHUB_TOKEN` deben ser gestionadas como secretos en GitHub y tener los permisos mínimos necesarios para operar.

## Enlace de Dashboard

*Aquí se puede colocar el enlace público al dashboard de Power BI una vez que esté disponible.*

`[Enlace al Dashboard de Power BI]` (Aún no disponible)
