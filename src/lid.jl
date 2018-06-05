# lid.jl
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

using Text: Text, BKG

export lid_train, lid_save, lid_load, lid

# function to train the model using training data file
function lid_train(filename::String)
    train_data  = map(l -> split(chomp(l), '\t')[2], filelines(filename))
    train_truth = map(l -> split(chomp(l), '\t')[1], filelines(filename))
    bkgmodel, fextractor, model = tc_train(train_data, train_truth, lid_iterating_tokenizer, mincount = 2, cutoff = 1e10,
                                           trainer = (fvs, truth, init_model) -> train_mira(fvs, truth, init_model, iterations = 20, k = 2, C = 0.01, average = true),
                                           iteration_method = :eager)
    return bkgmodel, fextractor, model
end

# function to save the model to file
function lid_save(filename::String, bkgmodel::Text.BKG, model::LinearModel{String})
    jldopen(filename, "w", compress=true) do file
        g = g_create(file, "lid")
        g["bkgmodel_dict"]  = Dict(bkgmodel.dict)
        g["bkgmodel_index"] = bkgmodel.index
        g["bkgmodel_stats"] = bkgmodel.stats
        g["model"]          = model
    end
end

# function to load the model from file
function lid_load(filename::String)
    bkgmodel, model = None, None
    jldopen(filename, "r") do file
        g = file["lid"]
        bkgmodel_dict   = read(g["bkgmodel_dict"])
        bkgmodel_index  = read(g["bkgmodel_index"])
        bkgmodel_stats  = read(g["bkgmodel_stats"])
        bkgmodel    = Text.BKG(DefaultDict(1, bkgmodel_dict), bkgmodel_index, bkgmodel_stats)
        model       = read(g["model"])
    end
    return bkgmodel, ptext -> Text.tc_features(ptext, bkgmodel), model
end

# function to detect language of text using model
function detect_language(text::String, fextractor::Function, model::LinearModel{String})
    fv      = fextractor(lid_iterating_tokenizer(text))
    scores  = score(model, fv)
    bidx, b = best(scores)
    return model.index_class[bidx]
end

# function to detect language from HTTP Request
function lid(req::Request, result::Dict, fextractor::Function, model::LinearModel{String})
    if req.method == "PUT"
        text    = bytestring(req.data)
        lang    = detect_language(text, fextractor, model)
        result["text"]      = text
        result["language"]  = lang
    elseif req.method == "GET"
        result["all_languages"] = model.index_class
    else
        result["language"]  = "error"
    end
end

