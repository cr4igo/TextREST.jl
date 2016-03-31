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

println("[START] starting training LID Model")
@time bkgmodel, fextractor, model = lid_train("data/text.tsv");
println("[END]   finished training LID Model")

# ------------------------------------------------------------------------------

println("[START] starting Test Set 1")

server = text_rest_server(fextractor, model)

@async run(server, host=ip"127.0.0.1", port=8000)

ret = Requests.get("http://localhost:8000/lid")
res = Requests.json(ret)
println(res)
@test res["resource"] == "lid"
@test length(res["all_languages"]) == 18

ret = Requests.put("http://localhost:8000/lid"; data = "hello world")
res = Requests.json(ret)
println(res)
@test res["resource"] == "lid"
@test res["text"] == "hello world"
@test res["language"] == "en"

ret = Requests.get("http://localhost:8000/blah")
res = Requests.json(ret)
println(res)
@test res["resource"] == 404

# close(server)
close(server.http.sock)

println("[END]   finished Test Set 1")

# ------------------------------------------------------------------------------

println("[START] starting saving LID Model")
@time lid_save("data/test.jld", bkgmodel, model)
println("[END]   finished saving LID Model")

println("[START] starting loading LID Model")
@time bkgmodel, fextractor, model = lid_load("data/test.jld")
println("[END]   finished loading LID Model")

# ------------------------------------------------------------------------------

println("[START] starting Test Set 2")

server = text_rest_server(fextractor, model)

@async run(server, host=ip"127.0.0.1", port=8000)

ret = Requests.get("http://localhost:8000/lid")
res = Requests.json(ret)
println(res)
@test res["resource"] == "lid"
@test length(res["all_languages"]) == 18

ret = Requests.put("http://localhost:8000/lid"; data = "hello world")
res = Requests.json(ret)
println(res)
@test res["resource"] == "lid"
@test res["text"] == "hello world"
@test res["language"] == "en"

ret = Requests.get("http://localhost:8000/blah")
res = Requests.json(ret)
println(res)
@test res["resource"] == 404

# close(server)
close(server.http.sock)

println("[END]   finished Test Set 2")
