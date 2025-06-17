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
    CursoID NVARCHAR(100) PRIMARY KEY,
    NombreCurso NVARCHAR(255),
    Unidad NVARCHAR(50)
);

CREATE TABLE Usuarios (
    UsuarioID NVARCHAR(255) PRIMARY KEY,
    NombreUsuario NVARCHAR(255),
    URLPerfil NVARCHAR(1024),
    TipoUsuario NVARCHAR(100)
);

CREATE TABLE Proyectos (
    ProyectoID BIGINT PRIMARY KEY,
    NombreProyecto NVARCHAR(255),
    RepoFullName NVARCHAR(512),
    CursoID NVARCHAR(100) NULL,
    Descripcion NVARCHAR(MAX),
    URLRepositorio NVARCHAR(1024),
    FechaCreacion DATETIME,
    FechaUltimaActualizacion DATETIME,
    LenguajePrincipal NVARCHAR(100),
    Stars INT,
    Forks INT,
    OpenIssues INT,
    FechaUltimaActividad DATETIME NULL
);

ALTER TABLE Proyectos ADD CONSTRAINT FK_Proyectos_Cursos FOREIGN KEY (CursoID) REFERENCES Cursos(CursoID);

CREATE TABLE ColaboradoresPorProyecto (
    ProyectoID BIGINT NOT NULL,
    UsuarioID NVARCHAR(255) NOT NULL,
    PRIMARY KEY (ProyectoID, UsuarioID),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID) ON DELETE CASCADE,
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID) ON DELETE CASCADE
);

CREATE TABLE Issues (
    IssueID BIGINT PRIMARY KEY,
    ProyectoID BIGINT,
    NumeroIssue INT,
    Titulo NVARCHAR(MAX),
    Estado NVARCHAR(50),
    CreadorID NVARCHAR(255),
    AsignadoID NVARCHAR(255),
    FechaCreacion DATETIME,
    FechaActualizacion DATETIME,
    FechaCierre DATETIME NULL,
    URLIssue NVARCHAR(1024),
    Comentarios INT,
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID) ON DELETE CASCADE
);

CREATE TABLE Commits (
    CommitSHA NVARCHAR(40) PRIMARY KEY,
    ProyectoID BIGINT,
    AutorID NVARCHAR(255),
    CommitterID NVARCHAR(255),
    Mensaje NVARCHAR(MAX),
    FechaCommit DATETIME,
    URLCommit NVARCHAR(1024),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID) ON DELETE CASCADE
);

CREATE TABLE ProyectoFrameworks (
    ProyectoID BIGINT,
    Framework NVARCHAR(100),
    PRIMARY KEY (ProyectoID, Framework),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID) ON DELETE CASCADE
);

CREATE TABLE ProyectoLibrerias (
    ProyectoID BIGINT,
    Libreria NVARCHAR(100),
    LenguajeContexto NVARCHAR(100),
    PRIMARY KEY (ProyectoID, Libreria, LenguajeContexto),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID) ON DELETE CASCADE
);

CREATE TABLE ProyectoBasesDeDatos (
    ProyectoID BIGINT,
    BaseDeDatos NVARCHAR(100),
    PRIMARY KEY (ProyectoID, BaseDeDatos),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID) ON DELETE CASCADE
);

CREATE TABLE ProyectoCICD (
    ProyectoID BIGINT,
    HerramientaCI_CD NVARCHAR(100),
    PRIMARY KEY (ProyectoID, HerramientaCI_CD),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID) ON DELETE CASCADE
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
CREATE VIEW V_EstadisticasCICD AS
SELECT HerramientaCI_CD, COUNT(ProyectoID) AS Cantidad FROM ProyectoCICD GROUP BY HerramientaCI_CD;
GO
