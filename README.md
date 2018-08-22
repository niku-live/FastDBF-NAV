# FastDBF-NAV
Open source FastDBF library port for Dynamics NAV platform

Port based on C# library [FastDBF](https://github.com/SocialExplorer/FastDBF)

Port implemented with following design decisions:
- Variable and procedure naming is left the same as in C# library to keep it as close as possible to original source code (even if used variable names differs from Dynamics NAV coding standard). This lets us easier update library in the future.
- All references to .NET classes are wrapped into special codeunits to make it possible to use library in cloud deployment. 
- List and Dictionary data types are reimplemented from scratch to support both C/AL and AL library versions with no code changes (while AL has native List and Dictionary support, C/AL has no such types).
- All references to FileStream are removed because working with files is not supported in cloud deployment.
