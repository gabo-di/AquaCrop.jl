```@meta
CurrentModule = AquaCrop
DocTestSetup = quote
    using AquaCrop
end
```

```@contents
Pages = ["gettingstarted.md"]
```

## Install

To install the package, open Julia and run:

```julia
using Pkg
Pkg.add("AquaCrop")
```

## [Basic Run](@id basic_run_section)

To maintain compatibility, we support the same input file formats used by the 
original implementation of [AquaCrop](https://github.com/KUL-RSDA/AquaCrop/) (v7.2).
To specify that this format should be used, call the [`NormalFileRun`](@ref) function:

```jldoctest basic_run_example; output = false
using AquaCrop
runtype = NormalFileRun()

# output
NormalFileRun()
```

Next we must specify where these input files are found. In this case, we use the
files in the test directory:

```jldoctest basic_run_example; output = false
parentdir = AquaCrop.test_dir #".../AquaCrop.jl/test/testcase"
endswith(parentdir, "test/testcase")

# output
true
```

Now we are ready to use the [`basic_run`](@ref) function:

```jldoctest basic_run_example
outputs = basic_run(; runtype=runtype, parentdir=parentdir);


isequal(size(outputs[:dayout]), (892, 89))

# output
true
```

All model results are stored in a collection of dataframes. For example, we can 
see the harvest dataframe via:

```jldoctest basic_run_example
outputs[:harvestsout]

# output
14×11 DataFrame
 Row │ RunNr  Nr     Date        DAP    Interval   Biomass           Sum(B)    ⋯
     │ Int64  Int64  Date        Int64  Quantity…  Quantity…         Quantity… ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │     1      0  2014-05-21      0      0.0 d      0.0 ton ha⁻¹      0.0 t ⋯
   2 │     1      1  2014-07-13     54     54.0 d  4.78668 ton ha⁻¹  4.78668 t
   3 │     1      2  2014-08-31    103     49.0 d  3.08189 ton ha⁻¹  7.86857 t
   4 │     1   9999  2014-11-01      0      0.0 d      0.0 ton ha⁻¹  9.17245 t
   5 │     2      0  2015-05-01      0      0.0 d      0.0 ton ha⁻¹      0.0 t ⋯
   6 │     2      1  2015-06-20     51    232.0 d  5.69329 ton ha⁻¹  5.69329 t
   7 │     2      2  2015-07-26     87     36.0 d  3.44309 ton ha⁻¹  9.13638 t
   8 │     2      3  2015-08-30    122     35.0 d  1.62555 ton ha⁻¹  10.7619 t
   9 │     2   9999  2015-10-25      0      0.0 d      0.0 ton ha⁻¹  11.9474 t ⋯
  10 │     3      0  2016-05-07      0      0.0 d      0.0 ton ha⁻¹      0.0 t
  11 │     3      1  2016-06-15     40    235.0 d  5.05947 ton ha⁻¹  5.05947 t
  12 │     3      2  2016-07-20     75     35.0 d  3.81457 ton ha⁻¹  8.87405 t
  13 │     3      3  2016-08-29    115     40.0 d  2.28277 ton ha⁻¹  11.1568 t ⋯
  14 │     3   9999  2016-10-29      0      0.0 d      0.0 ton ha⁻¹  12.5786 t
                                                               5 columns omitted
```

Similarly with the daily output dataframe `outputs[:dayout]`,
the result of the whole season dataframe `outputs[:seasonout]`,
the information for the evaluation dataframe `outputs[:evaldataout]`,
and the logger information in `outputs[:logger]`.
Note the output dataframes correspond to output files in a run of AquaCrop Fortran.

You can write the output in csv file using the [`write_out_csv`](@ref) function
```jldoctest basic_run_example
io = IOBuffer() 

write_out_csv(io, outputs[:seasonout]) # instead of io  you can use a filename like "example.csv"

io

# output
IOBuffer(data=UInt8[...], readable=true, writable=true, seekable=true, append=false, size=925, maxsize=Inf, ptr=926, mark=-1)
```


### Using TOML files

If you prefer to use TOML and CSV files for configuring the input, then 
use the function [`TomlFileRun`](@ref), as in the following example:

```jldoctest 
runtype = TomlFileRun();
parentdir = AquaCrop.test_toml_dir  #".../AquaCrop.jl/test/testcase/TOML_FILES"

outputs = basic_run(; runtype=runtype, parentdir=parentdir);

isequal(size(outputs[:dayout]), (892, 89))

# output

true
```

For more detailed examples, see the [user guide](https://gabo-di.github.io/AquaCrop.jl/dev/userguide/).
