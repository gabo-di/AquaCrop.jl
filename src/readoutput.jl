# These functions allow reading the output files produced by the
# original AquaCrop Fortran code

"""
    read_orig_ac_output_dayout(io)       -> DataFrame
    read_orig_ac_output_dayout(filename) -> DataFrame

Reads the daily output file produced by the original AquaCrop Fortran
code (e.g. `OttawaPROday.OUT`) and returns the contents as a
`DataFrame`.

Note that this function cannot read the "PRM" dayily output file
format that contains output for multiple runs in one file.
"""
function read_orig_ac_output_dayout(io::IO)
    # Note: There are two header lines.  The first line typically has
    #       the name of the column, and the second line the unit.
    #       Some columns such as "Day" or "Month" don't have a unit,
    #       and some column names such as "WC 2" contain a space.
    #       Luckily, all column names with a space are of the form
    #       "<colname> <number>", so it is easy to fix.
    #
    # TODO: Column names in the header "WC01" to "WC12" and "ECe01" to
    #       "ECe12" have a number below them, where other column names
    #       have the units (e.g. "ton/ha").  Currently, these numbers
    #       are simply added to the column names.
    nheaderlines = 4
    nfield = 98
    nfield_hdr1 = 114  # before fixup
    nfield_hdr2 = 93   # before fixup

    lines = readlines(io)
    if length(lines) < nheaderlines
        throw(ArgumentError("File must contain at least $nheaderlines lines"))
    end
    if lines[1][1:12] != "AquaCrop 7.2"
        throw(ArgumentError("Daily output file must start with \"AquaCrop 7.2\" on the first line."))
    end
    if lines[2] != ""
        throw(ArgumentError("Expected empty second line."))
    end
    if occursin(r"^\s*Run:\s*\d+\s*", lines[3])
        throw(ArgumentError("This is a multi-run output file (PRM file, contains a \"Run:\" line), this function reads a single run (PRO file)"))
    end
    # read header line 1
    hdr1 = split(lines[3])
    if length(hdr1) != nfield_hdr1
        throw(ArgumentError("Unexpected number of words on first header line (line 3): expected $nfield_hdr1, got $(length(hdr1))."))
    end
    # For header line 1, some fields are unfortunately split by
    # whitespace (e.g. "WC 1"), where the second part is always a
    # number.  This loop joins these fields back together.
    i = 2
    while i <= length(hdr1)
        if occursin(r"^\d+$", hdr1[i])
            hdr1[i-1] *= " " * hdr1[i]
            deleteat!(hdr1, i)
        else
            i += 1
        end
    end
    if length(hdr1) != nfield
        throw(ArgumentError("Wrong number of fields in first header line: expected $nfield, got $(length(hdr1))"))
    end
    # read header line 2
    hdr2 = split(lines[4])
    if length(hdr2) != nfield_hdr2
        throw(ArgumentError("Unexpected number of words on second header line (line 4): expected $nfield_hdr2, got $(length(hdr2))."))
    end
    # prepend empty fields that are missing in that line
    prepend!(hdr2, fill("", nfield - nfield_hdr2))
    if length(hdr2) != nfield
        throw(ArgumentError("Wrong number of fields in second header line: expected $nfield, got $(length(hdr2))"))
    end
    # now that they have the same number of fields, join the fields of
    # header line 1 and 2
    colnames = hdr1 .* " " .* hdr2

    # read data into a DataFrame
    data_str = join(replace.(strip.(lines[nheaderlines + 1:end]), r"\s+" => ", "), "\n")
    df = DataFrame(CSV.File(IOBuffer(data_str); delim=',', header=false), colnames; makeunique=true)

    return df
end

read_orig_ac_output_dayout(filename::AbstractString) =
    open(filename, "r") do io; read_orig_ac_output_dayout(io); end
