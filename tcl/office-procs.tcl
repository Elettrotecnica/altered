ad_library {

    This library supports the conversion of office file formats (xls,
    doc, odt, pdf...) from and to different formats.

    @author Antonio Pisano

}

namespace eval alt {}

ad_proc -public alt::exec {
    cmd
} {    
    Executes the specified external command first verifiying if
    utility exists and then taking care of eventual error statuses

    @return output of the command
} {
    set util [lindex $cmd 0]
    set util [util::which $util]
    if {$util eq ""} {
	error "[lindex $cmd 0] executable not available."
    }

    # use absolute path for utility when found
    set cmd [list $util {*}[lrange $cmd 1 end]]

    set status [catch {
	set retval [::exec {*}$cmd]
    } result]

    if { $status == 0 } {
	return $retval

        # The command succeeded, and wrote nothing to stderr.
        # $result contains what it wrote to stdout, unless you
        # redirected it
    } elseif { $::errorCode eq "NONE" } {
        # The command exited with a normal status, but wrote something
        # to stderr, which is included in $result.
	ns_log notice "'$cmd' ERROR $result"
    } else {
        switch -exact -- [lindex $::errorCode 0] {
            CHILDKILLED {
		lassign $::errorCode - pid sigName msg
                # A child process, whose process ID was $pid,
                # died on a signal named $sigName.  A human-
                # readable message appears in $msg.
		error "'$cmd' ERROR $pid $msg"
            }
            CHILDSTATUS {
		lassign $::errorCode - pid code
                # A child process, whose process ID was $pid,
                # exited with a non-zero exit status, $code.
		error "$cmd' ERROR $pid $code"
            }
            CHILDSUSP {
		lassign $::errorCode - pid sigName msg
                # A child process, whose process ID was $pid,
                # has been suspended because of a signal named
                # $sigName.  A human-readable description of the
                # signal appears in $msg.
		error "'$cmd' ERROR $sigName $msg"
            }
            POSIX {
		lassign $::errorCode - errName msg
                # One of the kernel calls to launch the command
                # failed.  The error code is in $errName, and a
                # human-readable message is in $msg.
		error "'$cmd' ERROR $errName $msg"
            }
            default {
		error "'$cmd' Unexpected error"
            }
        }
    }
}

namespace eval alt::office {}

ad_proc -public alt::office::convert  {
    input
    extension
} {
    Converts supplied file from its format to another.

    @param input absolute path to the file to be converted.

    @param extension extension for the converted file. Must be one of
    those supported by the LibreOffice suite, as this is internally
    used for conversion.

    @return path to the resulting file in case conversion succeeds. An
    error in every other case.
} {
    set input_extension [file extension $input]

    # nothing to do
    if {$input_extension eq $extension} {
	return
    }

    set tmpdir [file dirname [ad_tmpnam]]
    set outdir [file dirname $input]

    # LibreOffice needs to write in its home directory while
    # converting. Must make sure it is a place we have write
    # permissions for.
    alt::exec [subst {bash -c "HOME=${tmpdir}; libreoffice --headless --convert-to ${extension} ${input} --outdir ${outdir}"}]
    
    set extension_length [string length $input_extension]
    set input_name [string range $input 0 end-${extension_length}]
    set output "${input_name}.${extension}"
    if {![file exists $output]} {
	error "Conversion didn't produce expected file '${output}'."
    }

    return $output
}

ad_proc -public alt::office::htmldoc  {
  -in:required
  -out
  {-fontsize 8}
  {-left   "1cm"}
  {-right  "1cm"}
  {-top    "0cm"}
  {-bottom "0cm"}
} {
    Converts the specified HTML into a pdf. It is possible to specify
    some htmldoc options for conversion.

    @param in Input file

    @param out output file. If not specified, will be generated
    automatically.

    @return path to the output file
} {
    if {[info exists out]} {
	file delete $out
    } else {
	set out [ad_tmpnam].pdf
    }

    alt::exec [subst {
	htmldoc --webpage --header ... --footer ... --quiet \
	    --left     $left \
	    --right    $right \
	    --top      $top \
	    --bottom   $bottom \
	    --fontsize $fontsize \
	    -f $out $in
    }]
    
    if {![file exists $out]} {
	error "Conversion didn't produce an output file. Error was: $errmsg"
    }

    return $out
}

ad_proc -public alt::office::trml2pdf {
  -in:required
  -out:required
} {
    Converts the specified rml into a pdf using trml2pdf utility.

    @param in Input file

    @param out output file. If not specified, will be generated
    automatically.

    @return path to the output file
} {
    if {[info exists out]} {
	file delete $out
    } else {
	set out [ad_tmpnam].pdf
    }

    alt::exec [subst {trml2pdf $in > $out}]
    
    if {![file exists $out]} {
	error "Conversion didn't produce an output file. Error was: $errmsg"
    }

    return $out
}

ad_proc -public alt::office::merge_pdf  {
  -files:required
  -out
  {-n_copies 1}
  -collate:boolean
} {
    Merge specified 'files' into a single 'out' pdf.  If specified,
    multiple copies will be produced.  'collate_p' will decide if
    files will be collated, or simply appended multiple times in their
    respective order.
} {
    if {![info exists out]} {
	set out [ad_tmpnam].pdf
    }

    foreach f $files {
      if {![file exists $f]} {
	error "File $f doesn't exists"
      }
    }

    set command [list pdftk]
    # Collate means n times the documents in their respective order...
    if {$collate_p} {
	for {set i 0} {$i < $n_copies} {incr i} {
	    foreach f $files {
		lappend command $f
	    }
	}
    # ...otherwise they will be in theis respective order n times
    } else {
	foreach f $files {
	    for {set i 0} {$i < $n_copies} {incr i} {
		lappend command $f
	    }
	}
    }
    lappend command cat output $out

    alt::exec $command

    return $out
}

ad_proc -public alt::office::pdf_n_pages  {
  in
} {
    Gets the number of pages of a pdf
} {
    set pdftk [util::which pdftk]
    if {$pdftk eq ""} {
	error "pdftk command not available"
    }
    set pdfinfo [exec $pdftk $in dump_data | grep NumberOfPages]
    if {$pdfinfo eq ""} {
	error "Can't find number of pages in file $in"
    } else {
	return [lindex $pdfinfo end]
    }
}

ad_proc -public alt::office::generate_barcode  {
  -data:required
  -output
  {-resolution ""}
} {
    Produces a barcode from text received as input using the barcode
    utility.

    @param data Text to be encoded.

    @param output Output file name. If omitted will be automatically
    generated. Format of this file will be an Encapsulated Postscript
    (.eps) when no resolution is specified, or a .png otherwise.

    @param resolution Specifed as \(width\)x\(height\), only in case
    we prefer a raster over a vector format.

    @return path to the output file
} {
    if {[info exists resolution]} {
	set res_tokens [split $resolution x]
	if {[llength $res_tokens] != 2} {
	    error "Invalid resolution"
	}
	lassign $res_tokens width height
	if {![string is integer -strict $width] ||
	    ![string is integer -strict $height]} {
	    error "Invalid resolution"
	}
    }

    set tmpnam [ad_tmpnam]
    set filename_in  $tmpnam.in
    set filename_eps $tmpnam.eps

    if {![info exists output]} {
	if {[info exists resolution]} {
	    set output $tmpnam.png
	} else {
	    set output $filename_eps
	}
    }

    alt::exec [subst {barcode -n -b $data -E -o $filename_eps}]

    if {[file extension $output] eq "eps"} {
	return $output
    }

    set cmd [list convert]
    if {[info exists resolution]} {
	# density is set to 10 times the resolution because this way
	# image won't lose quality when resized
	set resolution_10 [expr {$height * 10}]x[expr {$width  * 10}]
	lappend cmd -geometry $resolution -density $resolution_10
    }
    lappend cmd $filename_eps $output
    alt::exec $cmd
    file delete $filename_eps

    return $output
}
