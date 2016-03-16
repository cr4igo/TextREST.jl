# Language Detection REST Server using MIT Lincoln Lab’s Text.jl library

The Language Detection REST Server is an HTTP Server in Julia for detecting the language of a text sent as an HTTP PUT request data. The Server will give a JSON response with the language ISO 639-1 Code. It makes use of the Margin-infused relaxed algorithm (MIRA) for the language detection (multiclass classification) based on word and character n-grams using the MIT Lincoln Lab’s Text.jl (TEXT: Numerous tools for text processing) library.

## Prerequisites

* `Julia v0.3` - http://julialang.org *(Note: currently using v0.3)*
* `Text.jl` - https://github.com/mit-nlp/Text.jl
* `HttpServer.jl` - https://github.com/JuliaWeb/HttpServer.jl
* `JSON.jl` - https://github.com/JuliaLang/JSON.jl
* `wikipedia-extractor` - https://github.com/bwbaugh/wikipedia-extractor

## Installation

1. Install `Julia v0.3` from http://julialang.org/downloads/oldreleases.html. You can either use the pre-build binaries or build it from source.
2. Add the `julia/bin` to your PATH, you can run the following commands or add it to ~/.bashrc
    <pre>
    export JULIA_BIN=PATH_TO_JULIA/bin
    export PATH=${PATH}:${JULIA_BIN}
    </pre>
3. Install `Text.jl` - https://github.com/mit-nlp/Text.jl
    <pre>
    $ julia
    julia> Pkg.clone("https://github.com/saltpork/Stage.jl")
    julia> Pkg.clone("https://github.com/mit-nlp/Ollam.jl")
    julia> Pkg.clone("https://github.com/mit-nlp/Text.jl")
    </pre>
4. Install `HttpServer.jl` - https://github.com/JuliaWeb/HttpServer.jl
    <pre>
    julia> Pkg.add("HttpServer")
    </pre>
    OR
    <pre>
    julia> Pkg.clone("https://github.com/JuliaWeb/HttpServer.jl")
    </pre>
5. Install `JSON.jl` - https://github.com/JuliaLang/JSON.jl
    <pre>
    julia> Pkg.add("JSON")
    </pre>
    OR
    <pre>
    julia> Pkg.clone("https://github.com/JuliaLang/JSON.jl")
    </pre>
6. Clone this repository - https://github.com/trevorlewis/TEXT-Language-REST.git
    <pre>
    git clone https://github.com/trevorlewis/TEXT-Language-REST.git
    </pre>
7. Add `WikiExtractor.py` from `wikipedia-extractor` (https://github.com/bwbaugh/wikipedia-extractor) into the `TEXT-Language-REST/data` directory

## Project Files

* `lidHttpServer.jl`
    * This file, located in the `src` directory, is used to train the model for language detection and start a Julia HTTP Server on the localhost port 8000.
    * The training data file should be a TSV file with the first column containing the language of the text and the second column containing the text. The training data can be generated using `data.sh` or you can use your own training data TSV file.
    * The language of the text to be detected should be sent as a PUT request data and the Server will give a JSON reply of the language ISO 639-1 Code.
    <pre>
    **Usage:**
    julia lidHttpServer.jl 'filepath'
    *Where,*
    'filepath' *is the path to training data tsv file*
    </pre>
    <pre>
    **To start the server in the background:**
    $ nohup julia lidHttpServer.jl 'filepath' & echo $! > pid
    *Where,*
    & *is used to run in background*
    nohup *is used to ignore the hangup signal
    pid *is the filename which contains the pid of the process
    so that we can kill the process later using the pid.*
    </pre>
    <pre>
    **To test the language detection Julia HTTP Server:**
    $ curl -X PUT -d "enter some text here" http://127.0.0.1:8000
    *(Note: it returns an incorrect result for text of smaller length like Hello World etc)*
    </pre>

* `data.sh`
    * This script, located in the `data` directory, is used to prepare the training data for language detection.
    * It downloads the Wikipedia database XML dumps of the languages listed in the `languages.txt` file and then extracts plain text from the dumps using `WikiExtractor.py` from `wikipedia-extractor` (https://github.com/bwbaugh/wikipedia-extractor).
    * Then it preprocesses the plain text files into TSV files such that it contains the language of the article text, article ID, article URL, article title and article text.
    * Finally, it combines 'n' random lines of all the files into a single TSV file such that it contains the language of the article text and the article text.
    * *Note: This script downloads the Wikipedia database XML dumps, extracts plain text from the dumps and preprocesses the plain text files into TSV files only once and uses this preprocessed TSV files to generate the training data. So you can delete the folders which contain the Wikipedia database XML dumps and the preprocessed plain text files but keep the preprocessed TSV files to generate new training or test data files.*
    <pre>
    **Usage:**
    data.sh [options]
    **Options:**
    -l, --lang  : languages file name
    -f, --file  : output file name
    -n, --num   : number of lines for each file
    **Example:**
    $ ./data.sh -l=languages.txt -f=text.tsv -n=1000
    </pre>

* `languages.txt`
    * This file, located in the `data` directory, contains the ISO 639-1 Codes of languages one on each line.
    * This file is used by `data.sh` to prepare the training data of the languages using the language codes in this file.

## Testing Your Installation

1. Run `$ julia src/lidHttpServer.jl test/text.tsv`
2. Open localhost:8000 or http://127.0.0.1:8000 in a browser.
3. You should see a JSON array of 18 language codes that can be detected by the Language Detection REST Server.

## Note

* The size of the files generated by `data.sh` for the 18 languages listed in `languages.txt` is as follows:
    <pre>
    $ du -sch xml_bz2/ text_xml/ tsv/
    32G	xml_bz2/
    35G	text_xml/
    32G	tsv/
    97G	total
    </pre>
    But, the Wikipedia database XML dumps in the `xml_bz2` folder and preprocessed plain text files in the `text_xml` folders can be deleted after the  preprocessed TSV files in the `tsv` folder is genenrated.

