version 1.0

import "wf_titan_illumina_pe.wdl" as titan_illumina_pe

struct InputJSON {
  File read1_raw
  File read2_raw
  String samplename
  File primer_bed
}

workflow cli_wrapper {
  input {
    Array[InputJSON] inputSamples
  }

  scatter (sample in inputSamples){
    call titan_illumina_pe.titan_illumina_pe{
      input:
        samplename = sample.samplename,
        seq_method = "Illumina paired-end",
        read1_raw = sample.read1_raw,
        read2_raw = sample.read2_raw,
        primer_bed = sample.primer_bed,
        pangolin_docker_image = "staphb/pangolin:2.3.2-pangolearn-2021-02-21"
    }
  }

}
