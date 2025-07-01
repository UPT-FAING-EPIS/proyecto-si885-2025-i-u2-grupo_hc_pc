-- =================================================================
-- Script de Base de Datos Idempotente para el Proyecto de Análisis Tecnológico
-- =================================================================
-- Este script asegura que el esquema se pueda (re)crear de forma segura en cada ejecución del pipeline.

-- Paso 1: Eliminar Vistas existentes para evitar conflictos.
DROP VIEW IF EXISTS V_EstadisticasFechasCreacion;
DROP VIEW IF EXISTS V_EstadisticasUnidades;
DROP VIEW IF EXISTS V_ProyectosConLenguajePrincipal;
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
DROP TABLE IF EXISTS ProyectoLenguajes;
DROP TABLE IF EXISTS Commits;
DROP TABLE IF EXISTS Issues;
DROP TABLE IF EXISTS ColaboradoresPorProyecto;
DROP TABLE IF EXISTS ProyectoUnidades;
DROP TABLE IF EXISTS Proyectos;
DROP TABLE IF EXISTS Usuarios;
DROP TABLE IF EXISTS Lenguajes;
DROP TABLE IF EXISTS FechasCreacion;
DROP TABLE IF EXISTS Cursos;
GO

-- Paso 3: Crear las Tablas desde cero.
CREATE TABLE Cursos (
    CursoID NVARCHAR(100) PRIMARY KEY,
    NombreCurso NVARCHAR(255),
    Unidad NVARCHAR(50)
);
GO

CREATE TABLE Lenguajes (
    LenguajeID NVARCHAR(100) PRIMARY KEY,
    NombreLenguaje NVARCHAR(255),
    Clasificacion NVARCHAR(100) -- Frontend, Backend, Fullstack, Mobile, Data Science, etc.
);
GO

CREATE TABLE FechasCreacion (
    FechaCreacionID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Año INT,
    Mes NVARCHAR(20) -- Enero, Febrero, Marzo, etc.
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
    FechaCreacionID BIGINT NULL,
    Descripcion NVARCHAR(MAX),
    URLRepositorio NVARCHAR(1024),
    FechaCreacion DATETIME,
    FechaUltimaActualizacion DATETIME,
    Stars INT,
    Forks INT,
    OpenIssues INT,
    FechaUltimaActividad DATETIME NULL,
    Contexto NVARCHAR(MAX), -- Título del README
    FOREIGN KEY (CursoID) REFERENCES Cursos(CursoID),
    FOREIGN KEY (FechaCreacionID) REFERENCES FechasCreacion(FechaCreacionID)
);
GO

CREATE TABLE ProyectoUnidades (
    ProyectoID BIGINT PRIMARY KEY,
    FechaCreacion DATETIME,
    Unidad NVARCHAR(50),
    Año NVARCHAR(10),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID) ON DELETE CASCADE
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

CREATE TABLE ProyectoLenguajes (
    ProyectoID BIGINT,
    LenguajeID NVARCHAR(100),
    BytesCount BIGINT DEFAULT 0,
    EsPrincipal BIT DEFAULT 0, -- Indica si es el lenguaje principal del proyecto
    PRIMARY KEY (ProyectoID, LenguajeID),
    FOREIGN KEY (ProyectoID) REFERENCES Proyectos(ProyectoID) ON DELETE CASCADE,
    FOREIGN KEY (LenguajeID) REFERENCES Lenguajes(LenguajeID) ON DELETE CASCADE
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
SELECT 
    l.NombreLenguaje, 
    l.Clasificacion,
    COUNT(pl.ProyectoID) AS CantidadProyectos,
    SUM(pl.BytesCount) AS TotalBytes
FROM Lenguajes l
LEFT JOIN ProyectoLenguajes pl ON l.LenguajeID = pl.LenguajeID
GROUP BY l.LenguajeID, l.NombreLenguaje, l.Clasificacion;
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

-- Vista para obtener el lenguaje principal de cada proyecto
CREATE VIEW V_ProyectosConLenguajePrincipal AS
SELECT 
    p.ProyectoID,
    p.NombreProyecto,
    p.RepoFullName,
    p.CursoID,
    l.NombreLenguaje AS LenguajePrincipal,
    l.Clasificacion AS ClasificacionLenguaje,
    pl.BytesCount AS BytesLenguajePrincipal,
    p.Stars,
    p.Forks,
    p.OpenIssues,
    p.FechaCreacion,
    p.FechaUltimaActualizacion,
    p.FechaUltimaActividad,
    p.Contexto
FROM Proyectos p
LEFT JOIN ProyectoLenguajes pl ON p.ProyectoID = pl.ProyectoID AND pl.EsPrincipal = 1
LEFT JOIN Lenguajes l ON pl.LenguajeID = l.LenguajeID;
GO

-- Vista para estadísticas de unidades académicas
CREATE VIEW V_EstadisticasUnidades AS
SELECT 
    pu.Unidad,
    pu.Año,
    COUNT(p.ProyectoID) AS CantidadProyectos,
    AVG(CAST(p.Stars AS FLOAT)) AS PromedioStars,
    AVG(CAST(p.Forks AS FLOAT)) AS PromedioForks,
    AVG(CAST(p.OpenIssues AS FLOAT)) AS PromedioOpenIssues
FROM ProyectoUnidades pu
INNER JOIN Proyectos p ON pu.ProyectoID = p.ProyectoID
WHERE pu.Unidad IS NOT NULL AND pu.Unidad != ''
GROUP BY pu.Unidad, pu.Año;
GO

-- Vista para estadísticas de fechas de creación
CREATE VIEW V_EstadisticasFechasCreacion AS
SELECT 
    fc.Año,
    fc.Mes,
    COUNT(p.ProyectoID) AS CantidadProyectos,
    AVG(CAST(p.Stars AS FLOAT)) AS PromedioStars,
    AVG(CAST(p.Forks AS FLOAT)) AS PromedioForks,
    AVG(CAST(p.OpenIssues AS FLOAT)) AS PromedioOpenIssues,
    CASE fc.Mes 
        WHEN 'Enero' THEN 1 WHEN 'Febrero' THEN 2 WHEN 'Marzo' THEN 3 
        WHEN 'Abril' THEN 4 WHEN 'Mayo' THEN 5 WHEN 'Junio' THEN 6
        WHEN 'Julio' THEN 7 WHEN 'Agosto' THEN 8 WHEN 'Septiembre' THEN 9
        WHEN 'Octubre' THEN 10 WHEN 'Noviembre' THEN 11 WHEN 'Diciembre' THEN 12
    END AS NumeroMes
FROM FechasCreacion fc
INNER JOIN Proyectos p ON fc.FechaCreacionID = p.FechaCreacionID
GROUP BY fc.Año, fc.Mes;
GO
