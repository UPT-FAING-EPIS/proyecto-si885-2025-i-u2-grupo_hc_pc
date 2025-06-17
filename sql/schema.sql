-- =================================================================
-- Script de Base de Datos Idempotente para el Proyecto de Análisis Tecnológico
-- =================================================================
-- Este script asegura que el esquema se pueda (re)crear de forma segura en cada ejecución del pipeline.

-- Paso 1: Eliminar Vistas existentes para evitar conflictos.
DROP VIEW IF EXISTS V_EstadisticasCICD;
DROP VIEW IF EXISTS V_EstadisticasBasesDeDatos;
DROP VIEW IF EXISTS V_EstadisticasLibrerias;
DROP VIEW IF EXISTS V_EstadisticasFrameworks;
DROP VIEW IF EXISTS V_EstadisticasLenguajes;
GO

-- Paso 2: Eliminar Tablas existentes en el orden inverso de dependencia.
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
GO

-- Paso 3: Crear las Tablas desde cero.
CREATE TABLE Cursos (
    CursoID NVARCHAR(100) PRIMARY KEY,
    NombreCurso NVARCHAR(255),
    Unidad NVARCHAR(50)
);
GO

CREATE TABLE Usuarios (
    UsuarioID NVARCHAR(255) PRIMARY KEY,
    NombreUsuario NVARCHAR(255),
    URLPerfil NVARCHAR(1024),
    TipoUsuario NVARCHAR(100)
);
GO

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
    FechaUltimaActividad DATETIME NULL,
    FOREIGN KEY (CursoID) REFERENCES Cursos(CursoID)
);
GO

CREATE TABLE ColaboradoresPorProyecto (
    ProyectoID BIGINT NOT NULL,
    UsuarioID NVARCHAR(255) NOT NULL,
    PRIMARY KEY (ProyectoID, UsuarioID),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID) ON DELETE CASCADE,
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID) ON DELETE CASCADE
);
GO

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
GO

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
GO

CREATE TABLE ProyectoFrameworks (
    ProyectoID BIGINT,
    Framework NVARCHAR(100),
    PRIMARY KEY (ProyectoID, Framework),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID) ON DELETE CASCADE
);
GO

CREATE TABLE ProyectoLibrerias (
    ProyectoID BIGINT,
    Libreria NVARCHAR(100),
    LenguajeContexto NVARCHAR(100),
    PRIMARY KEY (ProyectoID, Libreria, LenguajeContexto),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID) ON DELETE CASCADE
);
GO

CREATE TABLE ProyectoBasesDeDatos (
    ProyectoID BIGINT,
    BaseDeDatos NVARCHAR(100),
    PRIMARY KEY (ProyectoID, BaseDeDatos),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID) ON DELETE CASCADE
);
GO

CREATE TABLE ProyectoCICD (
    ProyectoID BIGINT,
    HerramientaCI_CD NVARCHAR(100),
    PRIMARY KEY (ProyectoID, HerramientaCI_CD),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID) ON DELETE CASCADE
);
GO

-- Paso 4: Crear Vistas para el análisis en Power BI.
CREATE VIEW V_EstadisticasLenguajes AS
SELECT LenguajePrincipal, COUNT(ProyectoID) AS CantidadProyectos
FROM Proyectos
WHERE LenguajePrincipal IS NOT NULL AND LenguajePrincipal <> 'N/A'
GROUP BY LenguajePrincipal;
GO

CREATE VIEW V_EstadisticasFrameworks AS
SELECT Framework, COUNT(ProyectoID) AS CantidadProyectos
FROM ProyectoFrameworks
GROUP BY Framework;
GO

CREATE VIEW V_EstadisticasLibrerias AS
SELECT Libreria, LenguajeContexto, COUNT(ProyectoID) AS CantidadProyectos
FROM ProyectoLibrerias
GROUP BY Libreria, LenguajeContexto;
GO

CREATE VIEW V_EstadisticasBasesDeDatos AS
SELECT BaseDeDatos, COUNT(ProyectoID) AS CantidadProyectos
FROM ProyectoBasesDeDatos
GROUP BY BaseDeDatos;
GO

CREATE VIEW V_EstadisticasCICD AS
SELECT HerramientaCI_CD, COUNT(ProyectoID) AS CantidadProyectos
FROM ProyectoCICD
GROUP BY HerramientaCI_CD;
GO
