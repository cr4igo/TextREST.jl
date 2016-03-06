Language Detection HTTP Server using MIT Lincoln Lab’s Text.jl library
====================


Prerequisites
----------
- `Julia` - https://github.com/JuliaLang/julia/tree/release-0.3 *(Note: currently using v0.3)*
- `Text.jl` - https://github.com/mit-nlp/Text.jl
- `HttpServer.jl` - https://github.com/JuliaWeb/HttpServer.jl
- `wikipedia-extractor` - https://github.com/bwbaugh/wikipedia-extractor


Files
----------
- `languages.txt`
This file contains the ISO 639-1 Codes of languages one on each line.

- `data.sh`
This script is used to prepare the training data for language detection.
It downloads the Wikipedia database XML dumps of the languages listed in the `languages.txt` file and then extracts plain text from the dumps using `WikiExtractor.py` (https://github.com/bwbaugh/wikipedia-extractor).
Then it preprocesses the plain text files into TSV files such that it contains the language of the article text, article ID, article URL, article title and article text.
Finally, it combines 'n' random lines of all the files into a single TSV file such that it contains the language of the article text and the article text.
> **Usage:**
> data.sh [options]
> **Options:**
>     -l, --lang  : languages file name
>     -f, --file  : output file name
>     -n, --num   : number of lines for each file
> **Example:**
>     data.sh -l=languages.txt -f=text.tsv -n=1000

- `lidHttpServer.jl`
This file is used to train the model for language detection using the file generated using `data.sh` and start a Julia HTTP Server on the localhost port 8000. The language of the text to be detected should be sent as a PUT request data and the Server will give a JSON reply of the language ISO 639-1 Code.
> **Usage:**
> julia lidHttpServer.jl
> **To start the server in the background:**
> nohup julia lidHttpServer.jl & echo $! > pid
*Where,*
& *is used to run in background*
nohup *is used to ignore the hangup signal*
pid *is a file which contains the pid of the process so that we can kill the process later using the pid.*
**To test the language detection Julia HTTP Server:**
> curl -X PUT -d "enter some text here" http://127.0.0.1:8000
*(Note: it returns an incorrect result for text of smaller length like Hello World etc)*

