@echo off
title Manutencao de Computadores IFSP

:: Verifica se esta rodando como administrador
fltmc >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  ERRO: execute como administrador.
    echo  Clique com o botao direito em INICIO.bat e escolha "Executar como administrador".
    echo.
    pause
    exit /b 1
)

:: %~dp0 = pasta onde este .bat esta (pendrive ou copia no PC; qualquer letra de unidade)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0manutencao.ps1"

echo.
pause
