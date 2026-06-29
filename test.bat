SET NAME=Jacob
ECHO %NAME%          :: immediate expansion
SETLOCAL ENABLEDELAYEDEXPANSION
SET VAL=hello
ECHO !VAL!           :: delayed expansion
ENDLOCAL
