# HIPL (Html 'Include' Preprocessor in Lua)
The goal of that project is to be a simple drag & drop html compiler.
At the very least it should allow to include html files in another html file.

## Installation
Download main.lua file

## Usage
Change CONFIG variable at the top of the file if needed and run 
    lua main.lua
at root of the project.

## HTML commands
- allows to include another html file
        {{#include filepath}}
- needed in included file to ensure that path is still valid to resource
        {{!filepath templatePOVPath}}
