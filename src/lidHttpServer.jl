# lidHttpServer.jl
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# Usage:
#     julia lidHttpServer.jl 'filepath'
# Where,
#     'filepath' is the path to training data tsv file

using Text
using Stage, Ollam, DataStructures
using HttpServer
using JSON

if size(ARGS, 1) != 1
    println("Usage: lidHttpServer.jl 'filepath'")
    println("Where, 'filepath' is the path to training data tsv file")
    exit(0)
end
filepath = ARGS[1]
if !isfile(filepath)
    println(string("'", filepath, "' file not found!"))
    exit(0)
end

# ----------------------------------------------------------------------
# LID
# ----------------------------------------------------------------------

# train the model

train       = map(l -> split(chomp(l), '\t')[2], filelines(filepath))
train_truth = map(l -> split(chomp(l), '\t')[1], filelines(filepath))

languages   = unique(train_truth)

bkgmodel, fextractor, model = tc_train(train, train_truth, lid_iterating_tokenizer, mincount = 2, cutoff = 1e10,
                                       trainer = (fvs, truth, init_model) -> train_mira(fvs, truth, init_model, iterations = 20, k = 2, C = 0.01, average = true),
                                       iteration_method = :eager)

# ----------------------------------------------------------------------

# function to identify language from text using the model

function detectLang(text)
    fv      = fextractor(lid_iterating_tokenizer(text))
    scores  = score(model, fv)
    bidx, b = best(scores)
    return model.index_class[bidx]
end

# ----------------------------------------------------------------------

# HTTP Server to identify language from PUT Request data

http = HttpHandler() do req::Request, res::Response
    result = Dict()
    if req.method == "PUT"
        text            = bytestring(req.data)
        lang            = detectLang(text)
        result["text"]  = text
        result["lang"]  = lang
    elseif req.method == "GET"
        result          = languages
    else
        result["lang"]  = "error"
    end
    return Response(JSON.json(result))
end
http.events["error"]    = (client, err) -> println(err)
http.events["listen"]   = (saddr) -> println("Running on http://$saddr (Press CTRL+C to quit)")

server  = Server(http)
run(server, host=IPv4(127,0,0,1), port=8000)

