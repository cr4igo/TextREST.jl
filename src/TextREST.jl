# TextREST.jl
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

module TextREST

using Text.Text
using Stage, Ollam, DataStructures
using HttpServer, JSON
using JLD, HDF5

export text_rest_server

# function to get resource name from HTTP Request
function get_resource_name(req::Request)
    return strip(split(split(req.resource, "?")[1], "/")[2])
end

# function to return TEXT REST Server object
function text_rest_server(fextractor::Function, model::LinearModel{String})
    http = HttpHandler() do req::Request, res::Response
        result      = Dict()
        resource    = get_resource_name(req)
        result["resource"]  = resource
        if ismatch(r"^$", resource)
            result["resource"]  = "index"
        elseif ismatch(r"^lid$", resource)
            lid(req, result, fextractor, model)
        else
            result["resource"]  = 404
        end
        return Response(JSON.json(result))
    end
    http.events["error"]    = (client, err) -> println(err)
    http.events["listen"]   = (saddr) -> println("Running on http://$saddr (Press CTRL+C to quit)")

    server  = Server(http)
    
    return server
end

include("lid.jl")

end
