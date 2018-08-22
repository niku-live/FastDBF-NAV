# FastDBF-NAV
Open source FastDBF library port for Dynamics NAV platform.

Port based on C# library [FastDBF](https://github.com/SocialExplorer/FastDBF). As written in original description - this library is for reading/writing DBF files. Fast and easy to use. Supports writing to forward-only streams which makes it easy to write dbf files in a web server environment.

While in C/AL solutions we can use C# library directly, it cannot be used in AL cloud solutions, so port to C/AL / AL language should help using DBF files in NAV without depending on Azure functions.

Port implemented with the following design decisions:
- Variable and procedure naming is left the same as in C# library to keep it as close as possible to original source code (even if used variable names differs from Dynamics NAV coding standard). This lets us easier update library in the future.
- All references to .NET classes are wrapped into special codeunits to make it possible to use library in cloud deployment. 
- List and Dictionary data types are reimplemented from scratch to support both C/AL and AL library versions with no code changes (while AL has native List and Dictionary support, C/AL has no such types).
- All references to FileStream are removed because working with files is not supported in cloud deployment.

Important notice: for now it is the first release so not all functionality is fully tested. Use at your own risk.
