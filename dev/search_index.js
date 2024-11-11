var documenterSearchIndex = {"docs":
[{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"CurrentModule = AquaCrop\nDocTestSetup = quote\n    using AquaCrop\nend","category":"page"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"Pages = [\"gettingstarted.md\"]","category":"page"},{"location":"gettingstarted/#Install","page":"Getting Started","title":"Install","text":"","category":"section"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"To install the package you can do","category":"page"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"using Pkg\nPkg.add(url=\"https://github.com/gabo-di/AquaCrop.jl\")","category":"page"},{"location":"gettingstarted/#basic_run_section","page":"Getting Started","title":"Basic Run","text":"","category":"section"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"AquaCrop.jl is based on FAO's AquaCrop, to mantain compatibility we allow to upload the same configurations files that AquaCrop v7.1 allows,  this can be done using the NormalFileRun function","category":"page"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"using AquaCrop\nruntype = NormalFileRun()","category":"page"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"now that we have selected what kind of configuration files we will use, we give the address of the files, for this example we use the files in the test directory","category":"page"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"parentdir = AquaCrop.test_dir #\".../AquaCrop.jl/test/testcase\"\nendswith(parentdir, \"/AquaCrop.jl/test/testcase\")","category":"page"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"now we are ready to use the basic_run function","category":"page"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"outputs = basic_run(; runtype=runtype, parentdir=parentdir);\n\n\nisequal(size(outputs[:dayout]), (892, 89))\n\n# output\ntrue","category":"page"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"we can see the harvest dataframe via","category":"page"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"outputs[:harvestsout]\n\n# output\n14×11 DataFrame\n Row │ RunNr  Nr     Date        DAP    Interval   Biomass           Sum(B)    ⋯\n     │ Int64  Int64  Date        Int64  Quantity…  Quantity…         Quantity… ⋯\n─────┼──────────────────────────────────────────────────────────────────────────\n   1 │     1      0  2014-05-21      0      0.0 d      0.0 ton ha⁻¹      0.0 t ⋯\n   2 │     1      1  2014-07-13     54     54.0 d  4.80683 ton ha⁻¹  4.80683 t\n   3 │     1      2  2014-08-31    103     49.0 d  3.19971 ton ha⁻¹  8.00655 t\n   4 │     1   9999  2014-11-01      0      0.0 d      0.0 ton ha⁻¹  9.31949 t\n   5 │     2      0  2015-05-01      0      0.0 d      0.0 ton ha⁻¹      0.0 t ⋯\n   6 │     2      1  2015-06-20     51    232.0 d  5.68897 ton ha⁻¹  5.68897 t\n   7 │     2      2  2015-07-26     87     36.0 d  3.39526 ton ha⁻¹  9.08422 t\n   8 │     2      3  2015-08-30    122     35.0 d  1.55885 ton ha⁻¹  10.6431 t\n   9 │     2   9999  2015-10-25      0      0.0 d      0.0 ton ha⁻¹  11.8413 t ⋯\n  10 │     3      0  2016-05-07      0      0.0 d      0.0 ton ha⁻¹      0.0 t\n  11 │     3      1  2016-06-15     40    235.0 d  5.04462 ton ha⁻¹  5.04462 t\n  12 │     3      2  2016-07-20     75     35.0 d  3.78779 ton ha⁻¹  8.83241 t\n  13 │     3      3  2016-08-29    115     40.0 d  2.22597 ton ha⁻¹  11.0584 t ⋯\n  14 │     3   9999  2016-10-29      0      0.0 d      0.0 ton ha⁻¹  12.4664 t\n                                                               5 columns omitted","category":"page"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"similarly with the daily output dataframe outputs[:dayout], the result of the whole season dataframe outputs[:seasonout], the information for the evaluation dataframe outputs[:evaldataout], and the logger information in outputs[:logger]. Note the output's dataframes correspond to output files in a run of AquaCrop Fortran.","category":"page"},{"location":"gettingstarted/#Using-TOML-files","page":"Getting Started","title":"Using TOML files","text":"","category":"section"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"If you prefer to use TOML and csv files for configuring the input, then  use the function TomlFileRun like in the following example","category":"page"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"runtype = TomlFileRun();\nparentdir = AquaCrop.test_toml_dir  #\".../AquaCrop.jl/test/testcase/TOML_FILES\"\n\noutputs = basic_run(; runtype=runtype, parentdir=parentdir);\n\nisequal(size(outputs[:dayout]), (892, 89))\n\n# output\n\ntrue","category":"page"},{"location":"api/","page":"API","title":"API","text":"CurrentModule = AquaCrop","category":"page"},{"location":"api/","page":"API","title":"API","text":"Pages = [\"api.md\"]","category":"page"},{"location":"api/#AquaCrop-API","page":"API","title":"AquaCrop API","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"API documentation for AquaCrop.","category":"page"},{"location":"api/","page":"API","title":"API","text":"Pages = [\"api.md\"]","category":"page"},{"location":"api/#Types","page":"API","title":"Types","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"Modules = [AquaCrop]\nOrder = [:type]\nPrivate = false","category":"page"},{"location":"api/#AquaCrop.AquaCropField","page":"API","title":"AquaCrop.AquaCropField","text":"AquaCropField \n\nHas all the data for the simulation of a cropfield::AquaCropField variable stored in dictionaries.\n\nInitialize an object of this type using the function start_cropfield or making a deepcopy of another cropfield.\n\nSee also start_cropfield\n\n\n\n\n\n","category":"type"},{"location":"api/#AquaCrop.NoFileRun","page":"API","title":"AquaCrop.NoFileRun","text":"runtype = NoFileRun()\n\nIndicates the configuration will be loaded manualy via julia variables\n\n\n\n\n\n","category":"type"},{"location":"api/#AquaCrop.NormalFileRun","page":"API","title":"AquaCrop.NormalFileRun","text":"runtype = NormalFileRun()\n\nIndicates the configuration will be loading files like in AquaCrop fortran.\n\n\n\n\n\n","category":"type"},{"location":"api/#AquaCrop.TomlFileRun","page":"API","title":"AquaCrop.TomlFileRun","text":"runtype = TomlFileRun()\n\nIndicates the configuration will be loading TOML and csv files.\n\n\n\n\n\n","category":"type"},{"location":"api/#Methods","page":"API","title":"Methods","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"Modules = [AquaCrop]\nOrder = [:function]\nPrivate = false","category":"page"},{"location":"api/#AquaCrop.basic_run-Tuple{}","page":"API","title":"AquaCrop.basic_run","text":"outputs = basic_run(; kwargs...)\n\nRuns a basic AquaCrop simulation, the outputs variable has the final dataframes with the results of the simulation\n\nruntype allowed for now is NormalFileRun or TomlFileRun \n\nNormalFileRun will use the input from a files like in AquaCrop Fortran (see AquaCrop.jl/test/testcase)\n\nTomlFileRun will use the input from TOML files (see AquaCrop.jl/test/testcase/TOML_FILES)\n\nYou can see the daily result in outputs[:dayout]  the result of each harvest in outputs[:harvestsout] the result of the whole season in outputs[:seasonout] the information for the evaluation in outputs[:evaldataout] and the logger information in outputs[:logger]\n\n\n\n\n\n","category":"method"},{"location":"api/#AquaCrop.biomass-Tuple{AquaCropField}","page":"API","title":"AquaCrop.biomass","text":"biomass = biomass(cropfield::AquaCropField)\n\nReturns the biomass of the cropfield with units ton/ha\n\n\n\n\n\n","category":"method"},{"location":"api/#AquaCrop.canopycover-Tuple{AquaCropField}","page":"API","title":"AquaCrop.canopycover","text":"canopycover(cropfield::AquaCropField; actual=true)\n\nReturns the canopy cover of the cropfield in percentage of terrain covered.\n\nIf actual=true, returns the canopy cover just before harvesting, otherwise returns the canopy cover just after harvesting\n\nThe harvesting is done at the end of the day.\n\n\n\n\n\n","category":"method"},{"location":"api/#AquaCrop.change_climate_data!-Tuple{AquaCropField, DataFrames.DataFrame}","page":"API","title":"AquaCrop.change_climate_data!","text":"change_climate_data!(cropfield::AquaCropField, climate_data::DataFrame; kwargs...)\n\nChanges the climate data in the cropfield using the data in climate_data.\n\nNote that climate_data must have a column with :Date property, other wise we do not change anything. The function assumes that :Date goes day by day.\n\nclimate_data must also have one of the following climate properties [:Tmin, :Tmax, :ETo, :Rain].\n\n\n\n\n\n","category":"method"},{"location":"api/#AquaCrop.dailyupdate!-Tuple{AquaCropField}","page":"API","title":"AquaCrop.dailyupdate!","text":"dailyupdate!(cropfield::AquaCropField)\n\nUpdates the cropfield by one day\n\n\n\n\n\n","category":"method"},{"location":"api/#AquaCrop.dryyield-Tuple{AquaCropField}","page":"API","title":"AquaCrop.dryyield","text":"dryyield = dryyield(cropfield::AquaCropField)\n\nReturns the dry yield of the cropfield with units ton/ha\n\n\n\n\n\n","category":"method"},{"location":"api/#AquaCrop.freshyield-Tuple{AquaCropField}","page":"API","title":"AquaCrop.freshyield","text":"freshyield = freshyield(cropfield::AquaCropField)\n\nReturns the fresh yield of the cropfield with units ton/ha\n\n\n\n\n\n","category":"method"},{"location":"api/#AquaCrop.harvest!-Tuple{AquaCropField}","page":"API","title":"AquaCrop.harvest!","text":"harvest!(cropfield::AquaCropField)\n\nIndicates to make a harvest on the cropfield  it also makes a daily update along with the harvest\n\n\n\n\n\n","category":"method"},{"location":"api/#AquaCrop.season_run!-Tuple{AquaCropField}","page":"API","title":"AquaCrop.season_run!","text":"season_run!(cropfield::AquaCropField)\n\nUpdates the cropfield for all days in the current season\n\n\n\n\n\n","category":"method"},{"location":"api/#AquaCrop.setup_cropfield!-Tuple{AquaCropField, AquaCrop.AllOk}","page":"API","title":"AquaCrop.setup_cropfield!","text":"setup_cropfield!(cropfield::AquaCropField, all_ok::AllOk; kwargs...)\n\nSetups the cropfield variable,  and reads the configuration files  with information about the climate.\n\nAfter calling this function check if all_ok.logi == true\n\nSee also start_cropfield\n\n\n\n\n\n","category":"method"},{"location":"api/#AquaCrop.start_cropfield-Tuple{}","page":"API","title":"AquaCrop.start_cropfield","text":"cropfield, all_ok = start_cropfield(; kwargs...)\n\nStarts the cropfield::AquaCropField with the proper runtype.  it uses default values for runtype and parentdir if these kwargs are missing.\n\nIt returns a cropfield with default values for crop, soil, etc. You need to call the function setup_cropfield! to actually load the values that you want for these variables.\n\nAfter calling this function check if all_ok.logi == true\n\nSee also setup_cropfield!\n\n\n\n\n\n","category":"method"},{"location":"api/#Additional-Functions","page":"API","title":"Additional Functions","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"AquaCrop.check_kwargs\nAquaCrop.check_runtype\nAquaCrop.check_parentdir\nAquaCrop.check_nofilerun","category":"page"},{"location":"api/#AquaCrop.check_kwargs","page":"API","title":"AquaCrop.check_kwargs","text":"kwargs, all_ok = check_kwargs(outputs; kwargs...)\n\nRuns all the necessary checks on the kwargs.\n\nAfter calling this function check if all_ok.logi == true\n\nSee also check_runtype, check_parentdir, check_nofilerun\n\nExamples\n\njulia> kwargs, all_ok = AquaCrop.check_kwargs(Dict(:logger => String[]); runtype=TomlFileRun(), parentdir=pwd());\n\njulia> all_ok.logi == true\ntrue\n\n\n\n\n\n","category":"function"},{"location":"api/#AquaCrop.check_runtype","page":"API","title":"AquaCrop.check_runtype","text":"kwargs, all_ok = check_runtype(outputs; kwargs...)\n\nIf we do not have a kwarg for :runtype it sets it to NormalFileRun. If we do have that kwarg, then checks if it is an AbstractRunType.\n\nAfter calling this function check if all_ok.logi == true\n\nExamples\n\njulia> kwargs, all_ok = AquaCrop.check_runtype(Dict(:logger => String[]); runtype = TomlFileRun());\n\njulia> all_ok.logi == true\ntrue\n\n\n\n\n\n","category":"function"},{"location":"api/#AquaCrop.check_parentdir","page":"API","title":"AquaCrop.check_parentdir","text":"kwargs, all_ok = check_parentdir(outputs; kwargs...)\n\nIf we do not have a kwarg for parentdir it sets it to pwd(). If we do have that kwarg, then checks if that directory exists. \n\nAfter calling this function check if all_ok.logi == true\n\nExamples\n\njulia> kwargs, all_ok = AquaCrop.check_parentdir(Dict(:logger => String[]); parentdir=pwd());\n\njulia> all_ok.logi == true\ntrue\n\n\n\n\n\n","category":"function"},{"location":"api/#AquaCrop.check_nofilerun","page":"API","title":"AquaCrop.check_nofilerun","text":"kwargs, all_ok = check_nofilerun(outputs; kwargs...)\n\nIn case we select a runtype = NoFileRun() checks that we have all the necessary kwargs, these are:\n\nFor the project input we have the following necessary keywords: Simulation_DayNr1, Simulation_DayNrN, Crop_Day1, Crop_DayN, InitialClimDate each one of them must be a Date type.\n\nThe soil_type must be one of these strings indicating the soil type: [\"sandy clay\", \"clay\", \"clay loam\", \"loamy sand\", \"loam\", \"sand\", \"silt\", \"silty loam\", \"silty clay\"]\n\nThe crop_type must be one of these  strings indicating the crop type: [\"maize\", \"wheat\", \"cotton\", \"alfalfaGDD\"]\n\nWe also have the optional keys: [:co2i, :crop, :perennial_period, :soil, :soil_layers, :simulparam, :Tmin, :Tmax, :ETo, :Rain, :temperature_record, :eto_record, :rain_record, :management (with this we need to change projectinput.Management_Filename too)] which give more control when configurating the cropfield::AquaCropField, similarly to using NormalFileRun or TomlFileRun.\n\nAfter calling this function check if all_ok.logi == true\n\nExamples\n\njulia> using Dates\n\njulia> start_date = Date(2023, 1, 1); # January 1 2023\n\njulia> end_date = Date(2023, 6, 1); # June 1 2023\n\njulia> kwargs = (runtype = NoFileRun(), Simulation_DayNr1 = start_date, Simulation_DayNrN = end_date, Crop_Day1 = start_date, Crop_DayN = end_date, soil_type = \"clay\", crop_type = \"maize\", InitialClimDate = start_date);\n\njulia> kwargs, all_ok = AquaCrop.check_nofilerun(Dict(:logger => String[]); kwargs...);\n\njulia> all_ok.logi == true\ntrue\n\n\n\n\n\n","category":"function"},{"location":"license/#License","page":"License","title":"License","text":"","category":"section"},{"location":"license/","page":"License","title":"License","text":"using Markdown, AquaCrop \nMarkdown.parse_file(joinpath(pkgdir(AquaCrop), \"LICENSE\"))","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"CurrentModule = AquaCrop\nDocTestSetup = quote\n    using AquaCrop\nend","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"Pages = [\"userguide.md\"]","category":"page"},{"location":"userguide/#Basic-Run","page":"User Guide","title":"Basic Run","text":"","category":"section"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"For an example of a basic run using the function basic_run see the section Basic Run in Getting Started","category":"page"},{"location":"userguide/#Intermediate-Run","page":"User Guide","title":"Intermediate Run","text":"","category":"section"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"We start a crop field, to do this we need to set a runtype and the data directory ","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"using AquaCrop\n\nparentdir = AquaCrop.test_toml_dir #\".../AquaCrop.jl/test/testcase/TOML_FILES\"\nruntype = TomlFileRun()","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"The crop field is started using the function start_cropfield","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"cropfield, all_ok = start_cropfield(;runtype=runtype, parentdir=parentdir);\ndump(all_ok)\n\n# output\nAquaCrop.AllOk\n  logi: Bool true\n  msg: String \"\"","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"where cropfield is an struct of type AquaCropField with all the information of  the crop field, and all_ok tell us if the paramers have been loaded correctly  all_ok.logi == true, or not all_ok.logi == false. When this happens, you can see  the error kind in all_ok.msg. (Note that we do not raise exceptions in case you want to inspect the cropfield variable, like cropfield.outputs[:logger]).  In out example we see that all_ok.logi == true, so all went well up to now. ","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"We have a cropfield::AquaCropField variable with the soil and crop data,  and we have checked that the config files exist. Now we have to setup the cropfield  using the function setup_cropfield!, this will read the climate data, setup the cropfield, among other things.","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"setup_cropfield!(cropfield, all_ok; runtype=runtype);\ndump(all_ok)\n\n# output\nAquaCrop.AllOk\n  logi: Bool true\n  msg: String \"\"","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"We see that all_ok.logi == true so we have read all the data. We can update the cropfield day by day, this is done  using the dailyupdate! function","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"ndays = 30\nfor _ in 1:ndays\n    dailyupdate!(cropfield)\nend\n\nisequal(size(cropfield.dayout), (ndays, 89))\n\n# output\ntrue","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"we can see the daily output DataFrame in the field","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"cropfield.dayout\n\n# output\n30×89 DataFrame\n Row │ RunNr  Date        DAP    Stage  WC()        Rain       Irri       Surf ⋯\n     │ Int64  Date        Int64  Int64  Quantity…   Quantity…  Quantity…  Quan ⋯\n─────┼──────────────────────────────────────────────────────────────────────────\n   1 │     1  2014-05-21      1      1  866.491 mm     0.1 mm     0.0 mm     0 ⋯\n   2 │     1  2014-05-22      2      2  864.965 mm     1.9 mm     0.0 mm     0\n   3 │     1  2014-05-23      3      2   864.28 mm     2.4 mm     0.0 mm     0\n   4 │     1  2014-05-24      4      2  862.077 mm     1.2 mm     0.0 mm     0\n   5 │     1  2014-05-25      5      2  859.819 mm     1.3 mm     0.0 mm     0 ⋯\n   6 │     1  2014-05-26      6      2  858.465 mm     1.2 mm     0.0 mm     0\n   7 │     1  2014-05-27      7      2  857.867 mm     2.4 mm     0.0 mm     0\n   8 │     1  2014-05-28      8      2  856.889 mm     0.4 mm     0.0 mm     0\n  ⋮  │   ⋮        ⋮         ⋮      ⋮        ⋮           ⋮          ⋮           ⋱\n  24 │     1  2014-06-13     24      2  884.881 mm    17.4 mm     0.0 mm     0 ⋯\n  25 │     1  2014-06-14     25      2  874.395 mm     3.8 mm     0.0 mm     0\n  26 │     1  2014-06-15     26      2  866.108 mm     0.1 mm     0.0 mm     0\n  27 │     1  2014-06-16     27      2  862.106 mm     0.2 mm     0.0 mm     0\n  28 │     1  2014-06-17     28      2  868.995 mm    11.0 mm     0.0 mm     0 ⋯\n  29 │     1  2014-06-18     29      2  868.812 mm     4.1 mm     0.0 mm     0\n  30 │     1  2014-06-19     30      2  863.843 mm     0.2 mm     0.0 mm     0\n                                                  82 columns and 15 rows omitted","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"if we want to know the biomass of the current day we use biomass function","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"biomass(cropfield)\n\n# output\n1.9209359227956477 ton ha⁻¹","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"note that the result is in ton/ha, metric tonelades per hectare. The amount of dry yield of the current day is given by the dryyield function","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"dryyield(cropfield)\n\n# output\n1.762886258750845 ton ha⁻¹","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"and the fresh yield by the freshyield function","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"freshyield(cropfield)\n\n# output\n8.814431293754224 ton ha⁻¹","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"The canopy cover is given by the percentage of terrain covered by the crop,  for this use the function canopycover","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"canopycover(cropfield)\n\n# output\n49.26884612609828","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"If we want to make a harvest in the current day use harvest! function ","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"harvest!(cropfield)\n\ncropfield.harvestsout\n\n# output\n2×11 DataFrame\n Row │ RunNr  Nr     Date        DAP    Interval   Biomass           Sum(B)    ⋯\n     │ Int64  Int64  Date        Int64  Quantity…  Quantity…         Quantity… ⋯\n─────┼──────────────────────────────────────────────────────────────────────────\n   1 │     1      0  2014-05-21      0      0.0 d      0.0 ton ha⁻¹      0.0 t ⋯\n   2 │     1      1  2014-06-20     31     31.0 d  2.03767 ton ha⁻¹  2.03767 t\n                                                               5 columns omitted","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"note that harvest! also makes a daily update, now we have ndays+1 days","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"isequal(size(cropfield.dayout), (ndays+1, 89))\n\n# output\ntrue","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"another effect of the harvest! function is that changes the biomass","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"biomass(cropfield) # biomass is zero after a harvest day\n\n# output\n0.0 ton ha⁻¹","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"it also changes the canopy cover, we can see the value of it just before harvesting","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"canopycover(cropfield) # canopy cover just before harvesting\n\n# output\n49.904006947723616","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"and just after harvesting","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"canopycover(cropfield, actual=false) # canopy cover just after harvesting\n\n# output\n25.0","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"the harvesting is done at the end of the day, that is why we have two values of canopy cover.","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"If we make another daily update the canopy cover is actualized","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"dailyupdate!(cropfield)\ncanopycover(cropfield) \n\n# output\n27.827808455159015","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"since it was not a harvesting day it does not matter if we set actual=false","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"canopycover(cropfield, actual=false) \n\n# output\n27.827808455159015","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"finally we can run until the end of the season using season_run! function","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"season_run!(cropfield)\n\nisequal(size(cropfield.dayout), (164, 89))\n\n# output\ntrue","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"and check the output dataframe of the season using","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"cropfield.seasonout\n\n# output\n1×36 DataFrame\n Row │ RunNr  Date1       Rain       ETo        GD       CO2         Irri      ⋯\n     │ Int64  Date        Quantity…  Quantity…  Float64  Quantity…   Quantity… ⋯\n─────┼──────────────────────────────────────────────────────────────────────────\n   1 │     1  2014-05-21   487.5 mm   431.0 mm   1802.6  398.81 ppm     0.0 mm ⋯\n                                                              29 columns omitted","category":"page"},{"location":"userguide/#Advanced-Run","page":"User Guide","title":"Advanced Run","text":"","category":"section"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"The advanced run is still experimental, the idea is to:","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"Provide more control of the variables.\nNot use files for faster upload of values.\nTo be easy to integrate with Persefone.jl and other julia libraries.","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"Let's start calling some libraries and creating some variables","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"using AquaCrop\nusing DataFrames\nusing Dates\nusing StableRNGs\n\nrng = StableRNG(42)\n\n# Auxiliar variables to generate ficticius climate data\nstart_date = Date(2023, 1, 1) # January 1 2023\nend_date = Date(2023, 6, 1) # June 1 2023\ntmin = 15 # daily minimum temperature will be around this\ndelta_t = 10 # daily maximum temperature will be around tmin + delta_t\neto = 1 # daily ETo will be around this \nrain = 1 # daily rain will be around this","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"Now we will create a function to mockup some climate DataFrame","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"# Function to create a mockup climate DataFrame\nfunction create_mock_climate_dataframe(start_date::Date, end_date::Date, tmin, delta_t, eto, rain)\n    # Generate the date range\n    dates = collect(start_date:end_date)\n    \n    # Generate random climate columns (each column has the same number of rows as the date range)\n    Tmin = tmin .+ rand(rng, length(dates))\n    Tmax = Tmin .+ delta_t .+ rand(rng, length(dates))\n    ETo = eto .* abs.(randn(rng, length(dates)))\n    Rain = rain .* abs.(randn(rng, length(dates)))\n    \n    # Create the DataFrame\n    df = DataFrame(\n        Date = dates,\n        Tmin = Tmin,\n        Tmax = Tmax,\n        ETo = ETo,\n        Rain = Rain\n    )\n    \n    return df\nend\n\ndf = create_mock_climate_dataframe(start_date, end_date, tmin, delta_t, eto, rain)\n\n# output\n152×5 DataFrame\n Row │ Date        Tmin     Tmax     ETo        Rain\n     │ Date        Float64  Float64  Float64    Float64\n─────┼────────────────────────────────────────────────────\n   1 │ 2023-01-01  15.5805  25.7028  0.651892   2.91776\n   2 │ 2023-01-02  15.1912  25.8489  1.27642    0.633148\n   3 │ 2023-01-03  15.9711  26.3123  0.815404   1.05268\n   4 │ 2023-01-04  15.7434  26.2699  1.28974    0.205817\n   5 │ 2023-01-05  15.171   25.5827  0.21546    0.0733287\n   6 │ 2023-01-06  15.7048  26.1394  0.0967601  1.52228\n   7 │ 2023-01-07  15.441   26.284   0.238206   0.446309\n   8 │ 2023-01-08  15.804   26.2381  0.43073    0.539408\n  ⋮  │     ⋮          ⋮        ⋮         ⋮          ⋮\n 146 │ 2023-05-26  15.3848  26.1798  0.857995   0.433004\n 147 │ 2023-05-27  15.6592  26.1444  1.41443    2.38353\n 148 │ 2023-05-28  15.5007  26.292   0.226759   0.429369\n 149 │ 2023-05-29  15.6813  26.624   0.220586   0.88746\n 150 │ 2023-05-30  15.8692  26.2971  0.142944   0.235242\n 151 │ 2023-05-31  15.6776  26.629   0.331443   0.851964\n 152 │ 2023-06-01  15.9877  26.9083  0.160163   1.67827\n                                          137 rows omitted","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"this advanced run depends on sending all the configuration via a keyword variable ","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"# Generate the keyword object for the simulation\nkwargs = (\n\n    ## Necessary keywords\n\n    # runtype\n    runtype = NoFileRun(),\n\n    # project input\n    Simulation_DayNr1 = start_date,\n    Simulation_DayNrN = end_date,\n    Crop_Day1 = start_date,\n    Crop_DayN = end_date,\n\n    # soil\n    soil_type = \"clay\",\n\n    # crop\n    crop_type = \"maize\",\n\n    # Climate\n    InitialClimDate = start_date,\n\n\n\n    ## Optional keyworkds\n    \n    # Climate\n    Tmin = df.Tmin,\n    Tmax = df.Tmax,\n    ETo = df.ETo,\n    Rain = df.Rain,\n\n    # change soil properties\n    soil_layers = Dict(\"Thickness\" => 5.0)\n\n)\nnothing # ignore this line","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"the variable kwargs has some necessary keywords, like the runtype  where we specify that we will not use files to make the configuration  runtype = NoFileRun(), see NoFileRun, and some optional keywords, to pass the climate data, like temperature Tmin = df.Tmin, or additional information to change some properties of the variables, like soil_layers = Dict(\"Thickness\" => 5.0) To know more about the keywords see AquaCrop.check_nofilerun.","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"Once that we have created the kwargs we can start a cropfield","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"# start cropfield\ncropfield, all_ok = start_cropfield(; kwargs...)\ndump(all_ok)\n\n# output\nAquaCrop.AllOk\n  logi: Bool true\n  msg: String \"\"","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"see that the climate is empty","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"cropfield.raindatasim\n\n# output\nFloat64[]","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"now we setup the cropfield","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"setup_cropfield!(cropfield, all_ok; kwargs...)\ndump(all_ok)\n\n# output\nAquaCrop.AllOk\n  logi: Bool true\n  msg: String \"\"","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"and the climate is no longer empty","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"cropfield.raindatasim\n\n# output\n152-element Vector{Float64}:\n 2.9177565288611698\n 0.6331479661044\n 1.0526800752671774\n 0.20581692403731217\n 0.07332874480489955\n 1.5222784325808019\n 0.44630933889682284\n 0.5394084077226324\n 0.4667865106229535\n 0.9548987102476532\n ⋮\n 0.09979662306558626\n 0.8290059898452288\n 0.43300412658464604\n 2.383533709338484\n 0.429368530738495\n 0.8874604322470359\n 0.23524192561168275\n 0.8519635419668649\n 2.9177565288611698","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"Now that we have finished setting up the cropfield, we can update the cropfield day by day, this is done  using the dailyupdate! function","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"# daily update cropfield\nndays = 30\nfor _ in 1:ndays\n    dailyupdate!(cropfield)\nend\nisequal(size(cropfield.dayout), (ndays, 89))\n\n# output\ntrue","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"similarly to Intermediate Run,  if we want to make a harvest in the current day use harvest! function ","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"# harvest cropfield\nharvest!(cropfield)\n\ncropfield.harvestsout\n\n# output\n2×11 DataFrame\n Row │ RunNr  Nr     Date        DAP    Interval   Biomass           Sum(B)    ⋯\n     │ Int64  Int64  Date        Int64  Quantity…  Quantity…         Quantity… ⋯\n─────┼──────────────────────────────────────────────────────────────────────────\n   1 │     1      0  2023-01-01      0      0.0 d      0.0 ton ha⁻¹      0.0 t ⋯\n   2 │     1      1  2023-01-31     31      1.0 d  0.23564 ton ha⁻¹  0.23564 t\n                                                               5 columns omitted","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"We can also change the climate data in the middle of the run, first we create  a new mockup climate with the current simulation date of the cropfield","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"# change climate data\ndaynri_now = cropfield.gvars[:integer_parameters][:daynri]\nday_now, month_now, year_now = AquaCrop.determine_date(daynri_now)\ndate_now = Date(year_now, month_now, day_now)\ndf_new = create_mock_climate_dataframe(date_now, end_date, tmin, delta_t, eto, rain)\n\n# output\n121×5 DataFrame\n Row │ Date        Tmin     Tmax     ETo        Rain\n     │ Date        Float64  Float64  Float64    Float64\n─────┼────────────────────────────────────────────────────\n   1 │ 2023-02-01  15.6869  26.5836  1.71291    1.8238\n   2 │ 2023-02-02  15.9483  26.2946  0.100485   0.979034\n   3 │ 2023-02-03  15.2689  26.0057  0.482743   0.704698\n   4 │ 2023-02-04  15.7582  26.7011  0.503668   1.39689\n   5 │ 2023-02-05  15.4462  25.5794  1.34735    1.70537\n   6 │ 2023-02-06  15.1402  25.4986  0.49967    0.403604\n   7 │ 2023-02-07  15.0549  25.8906  0.225304   1.40783\n   8 │ 2023-02-08  15.715   26.1469  0.0636065  0.909276\n  ⋮  │     ⋮          ⋮        ⋮         ⋮          ⋮\n 115 │ 2023-05-26  15.5075  25.8814  1.00945    0.741913\n 116 │ 2023-05-27  15.6137  26.5237  0.9474     0.0554669\n 117 │ 2023-05-28  15.7396  25.877   0.684951   0.179529\n 118 │ 2023-05-29  15.8959  26.1849  1.82466    1.01259\n 119 │ 2023-05-30  15.1694  26.0627  1.5105     0.31451\n 120 │ 2023-05-31  15.2946  25.4924  2.04355    1.40788\n 121 │ 2023-06-01  15.9661  26.0386  0.835019   0.0228998\n                                          106 rows omitted","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"and change the climate using change_climate_data! function","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"change_climate_data!(cropfield, df_new; kwargs...)\n\nisapprox(cropfield.gvars[:float_parameters][:rain], df_new.Rain[1]) \n\n# output\ntrue","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"finally we can run until the end of the season using season_run! function","category":"page"},{"location":"userguide/","page":"User Guide","title":"User Guide","text":"season_run!(cropfield)\ntotal_days = length(collect(start_date:end_date))\nisequal(size(cropfield.dayout), (total_days, 89))\n\n# output\ntrue","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"CurrentModule = AquaCrop","category":"page"},{"location":"#Introduction","page":"Introduction","title":"Introduction","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"AquaCrop is a crop growth model developed by FAO’s Land and Water Division,  FAO-AquaCrop, to support food security and to analyze how environmental and management factors influence crop productivity. It focuses on simulating how water availability affects  the yield of herbaceous crops, making it ideal for situations where water is a  primary constraint in agriculture. AquaCrop was designed to balance simplicity  with precision and robustness. ","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"The original FAO's code is written in Fortran and available on github AquaCrop. AquaCrop.jl is a julia implementation that corresponds  to AquaCrop version 7.1, older or newer versions can have compatibility issues.  This repository is written with the idea to be possible to interact with other libraries from the julia ecosystem, like DatarFrames.jl, Makie.jl, StatsModels.jl, etc. But also to complement the models in Persefone.jl","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"The model is open-source available in AquaCrop.jl.  It is developed as part of the CAP4GI project.","category":"page"}]
}
