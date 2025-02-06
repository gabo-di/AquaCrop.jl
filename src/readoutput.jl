# These functions allow reading the output files produced by the
# original AquaCrop Fortran code

"""
    read_orig_ac_output_dayout(io)       -> DataFrame
    read_orig_ac_output_dayout(filename) -> DataFrame

Reads the daily output file produced by the original AquaCrop Fortran
code (e.g. `OttawaPROday.OUT`) and returns the contents as a
`DataFrame`.

Note: this function cannot read the "PRM"-style (`OttawaPRMday.OUT`)
      daily output file format that contains output for multiple runs
      in one file.
"""
function read_orig_ac_output_dayout(io::IO)
    # Note: There are four header lines, with the first two being just
    #       a preamble.  The third line has the name of the column,
    #       and the fourth line the column unit.  Some columns such as
    #       "Day" or "Month" don't have a unit, and some column names
    #       such as "WC 2" contain a space.  Luckily, all column names
    #       with a space are of the form "<colname> <number>", so we
    #       can fix it up after splitting the line on whitespace.
    #
    # TODO: Column names in the header "WC01" to "WC12" and "ECe01" to
    #       "ECe12" have a number below them, where other column names
    #       have the units (e.g. "ton/ha").  Currently, these numbers
    #       are simply added to the column names.

    # Number of lines in the file header
    nheaderlines = 4
    # These columns are missing on the third header line, these are
    # "Day", "Month", "Year", "DAP", "Stage" in the third header line
    ncol_units_missing = 5
    # Minimum number of columns we expect
    ncol_min = ncol_units_missing

    lines = readlines(io)
    if length(lines) < nheaderlines
        throw(ArgumentError("File must contain at least $nheaderlines lines"))
    end
    if lines[1][1:11] != "AquaCrop 7."
        throw(ArgumentError("Daily output file must start with \"AquaCrop 7.\" on the first line."))
    end
    if lines[2] != ""
        throw(ArgumentError("Expected empty second line."))
    end
    if occursin(r"^\s*Run:\s*\d+\s*", lines[3])
        throw(ArgumentError("This is a multi-run output file (PRM file, contains a \"Run:\" line), this function reads a single run (PRO file)"))
    end

    # Read third header line that contains the column names.  Column
    # names are split on whitespace, with the additional twist that
    # some columns names such as "WC 1" can also contain a space.  The
    # column names containing spaces always have a number in the
    # second part, so we use that to decide when to rejoin two column
    # names.
    hdr_colnames = split(lines[3])
    i = 2
    while i <= length(hdr_colnames)
        if occursin(r"^\d+$", hdr_colnames[i])
            hdr_colnames[i-1] *= " " * hdr_colnames[i]
            deleteat!(hdr_colnames, i)
        else
            i += 1
        end
    end
    if length(hdr_colnames) < ncol_min
        throw(ArgumentError("Expected at least $ncol_min column names in third header line, got $(length(hdr_colnames))"))
    end

    # Read fourth header line that contains the column units.  The
    # first columns do not have units, so we add an empty string for
    # them.
    hdr_colunits = split(lines[4])
    prepend!(hdr_colunits, fill("", ncol_units_missing))

    if length(hdr_colnames) != length(hdr_colunits)
        throw(ArgumentError("Column names and column units have different numbers of items: $(length(hdr_colnames)) != $(length(hdr_colunits))"))
    end

    # Create final column names by joining column names and units
    colnames = hdr_colnames .* " " .* hdr_colunits

    # Read data into a DataFrame
    data_str = join(replace.(strip.(lines[nheaderlines + 1:end]), r"\s+" => ", "), "\n")
    df = DataFrame(CSV.File(IOBuffer(data_str); delim=',', header=false), colnames; makeunique=true)

    return df
end

read_orig_ac_output_dayout(filename::AbstractString) =
    open(filename, "r") do io; read_orig_ac_output_dayout(io); end
