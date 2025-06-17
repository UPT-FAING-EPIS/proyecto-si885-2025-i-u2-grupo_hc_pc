-- Eliminar vistas y tablas existentes para permitir una re-ejecución limpia durante el desarrollo.
DROP VIEW IF EXISTS V_EstadisticasCICD;
DROP VIEW IF EXISTS V_EstadisticasBasesDeDatos;
DROP VIEW IF EXISTS V_EstadisticasLibrerias;
DROP VIEW IF EXISTS V_EstadisticasFrameworks;
DROP VIEW IF EXISTS V_EstadisticasLenguajes;

DROP TABLE IF EXISTS ProyectoCICD;
DROP TABLE IF EXISTS ProyectoBasesDeDatos;
DROP TABLE IF EXISTS ProyectoLibrerias;
DROP TABLE IF EXISTS ProyectoFrameworks;
DROP TABLE IF EXISTS Commits;
DROP TABLE IF EXISTS Issues;
DROP TABLE IF EXISTS ColaboradoresPorProyecto;
DROP TABLE IF EXISTS Proyectos;
DROP TABLE IF EXISTS Usuarios;
DROP TABLE IF EXISTS Cursos;

-- Creación de Tablas
CREATE TABLE Cursos (
    CursoID NVARCHAR(255) PRIMARY KEY,
    NombreCurso NVARCHAR(255) NOT NULL,
    Unidad NVARCHAR(50)
);

CREATE TABLE Usuarios (
    UsuarioID NVARCHAR(255) PRIMARY KEY,
    NombreUsuario NVARCHAR(255),
    URLPerfil NVARCHAR(2048),
    TipoUsuario NVARCHAR(100)
);

CREATE TABLE Proyectos (
    ProyectoID BIGINT PRIMARY KEY,
    NombreProyecto NVARCHAR(255) NOT NULL,
    RepoFullName NVARCHAR(512) UNIQUE NOT NULL,
    CursoID NVARCHAR(255),
    Descripcion NVARCHAR(MAX),
    URLRepositorio NVARCHAR(2048),
    FechaCreacion DATETIME2,
    FechaUltimaActualizacion DATETIME2,
    FechaUltimaActividad DATETIME2,
    LenguajePrincipal NVARCHAR(100),
    Stars INT,
    Forks INT,
    OpenIssues INT,
    FOREIGN KEY (CursoID) REFERENCES Cursos(CursoID)
);

CREATE TABLE ColaboradoresPorProyecto (
    ProyectoID BIGINT,
    UsuarioID NVARCHAR(255),
    PRIMARY KEY (ProyectoID, UsuarioID),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID),
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);

CREATE TABLE Issues (
    IssueID BIGINT PRIMARY KEY,
    ProyectoID BIGINT,
    NumeroIssue INT,
    Titulo NVARCHAR(MAX),
    Estado NVARCHAR(50),
    CreadorID NVARCHAR(255),
    AsignadoID NVARCHAR(255),
    FechaCreacion DATETIME2,
    FechaActualizacion DATETIME2,
    FechaCierre DATETIME2,
    URLIssue NVARCHAR(2048),
    Comentarios INT,
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID),
    FOREIGN KEY (CreadorID) REFERENCES Usuarios(UsuarioID),
    FOREIGN KEY (AsignadoID) REFERENCES Usuarios(UsuarioID)
);

CREATE TABLE Commits (
    CommitSHA NVARCHAR(40) PRIMARY KEY,
    ProyectoID BIGINT,
    AutorID NVARCHAR(255),
    CommitterID NVARCHAR(255),
    Mensaje NVARCHAR(MAX),
    FechaCommit DATETIME2,
    URLCommit NVARCHAR(2048),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID),
    FOREIGN KEY (AutorID) REFERENCES Usuarios(UsuarioID),
    FOREIGN KEY (CommitterID) REFERENCES Usuarios(UsuarioID)
);

CREATE TABLE ProyectoFrameworks (
    ProyectoID BIGINT,
    Framework NVARCHAR(100),
    PRIMARY KEY (ProyectoID, Framework),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID)
);

CREATE TABLE ProyectoLibrerias (
    ProyectoID BIGINT,
    Libreria NVARCHAR(100),
    LenguajeContexto NVARCHAR(100),
    PRIMARY KEY (ProyectoID, Libreria),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID)
);

CREATE TABLE ProyectoBasesDeDatos (
    ProyectoID BIGINT,
    BaseDeDatos NVARCHAR(100),
    PRIMARY KEY (ProyectoID, BaseDeDatos),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID)
);

CREATE TABLE ProyectoCICD (
    ProyectoID BIGINT,
    HerramientaCI_CD NVARCHAR(100),
    PRIMARY KEY (ProyectoID, HerramientaCI_CD),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID)
);
GO

-- Creación de Vistas para Estadísticas
CREATE VIEW V_EstadisticasFrameworks AS
SELECT Framework, COUNT(ProyectoID) AS Cantidad FROM ProyectoFrameworks GROUP BY Framework;
GO

CREATE VIEW V_EstadisticasLibrerias AS
SELECT Libreria, LenguajeContexto, COUNT(ProyectoID) AS Cantidad FROM ProyectoLibrerias GROUP BY Libreria, LenguajeContexto;
GO

CREATE VIEW V_EstadisticasBasesDeDatos AS
SELECT BaseDeDatos, COUNT(ProyectoID) AS Cantidad FROM ProyectoBasesDeDatos GROUP BY BaseDeDatos;
GO

CREATE VIEW V_EstadisticasCICD AS
SELECT HerramientaCI_CD, COUNT(ProyectoID) AS Cantidad FROM ProyectoCICD GROUP BY HerramientaCI_CD;
GO
