# Extensions

Walk relies on file extensions to define entity types. These include the following:
- `.fun` (Function): Executable logic. The file itself is the function. It begins with a strict static contract defining inputs (`in`) and outputs (`out`), followed by pure logic.
- `.str` (Structure): Data shapes. These files contain nothing but strictly typed property definitions.
- `.enum` (Enumeration): Defines a closed set of catergorical states or sum types.
- `.req` (Requirement): An interface file that defines a behavioral contract (set of requires `.fun` signatures) that a directory must fulfill.
