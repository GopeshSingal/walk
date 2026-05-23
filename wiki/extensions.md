# Extensions

Walk relies on file extensions to define entity types. These include the following:
- `.fun` (Function): Executable logic. The file itself is the function. It begins with a strict static contract defining inputs (`in`) and outputs (`out`), followed by pure logic.
- `.met` (Method): Executable logic. The file itself is a structure method, implicitly receiving `self`. Must be in a directory with a `.str` file.
- `.str` (Structure): Data shapes. These files contain nothing but strictly typed property definitions.
- `.enm` (Enumeration): Defines a closed set of catergorical states or sum types.
- `.req` (Requirement): An interface file that defines a behavioral contract (set of requires `.fun` signatures) that a directory must fulfill.

Base file names must be unique within a directory across all extensions (e.g., you cannot have `status.met` and `status.str` in the same folder).
