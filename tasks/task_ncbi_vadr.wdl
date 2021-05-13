version 1.0

task vadr {
  meta {
    description: "Runs NCBI's Viral Annotation DefineR for annotation and QC. See https://github.com/ncbi/vadr/wiki/Coronavirus-annotation"
  }
  input {
    File      genome_fasta
    String    samplename
    String    vadr_opts="--noseqnamemax -s -r --nomisc --mkey NC_045512 --lowsim5term 2 --lowsim3term 2 --fstlowthr 0.0 --alt_fail lowscore,fsthicnf,fstlocnf"
    String    docker="staphb/vadr:1.1.2"
    Int?      cpus = 8
  }
  String out_base = basename(genome_fasta, '.fasta')
  command <<<
    set -e

    # find available RAM
    RAM_MB=$(free -m | head -2 | tail -1 | awk '{print $2}')

    # run VADR
    v-annotate.pl \
      ~{vadr_opts} \
      --mxsize $RAM_MB \
      "~{genome_fasta}" \
      "~{out_base}"

    # package everything for output
    tar -C "~{out_base}" -czvf "~{out_base}.vadr.tar.gz" .

    # prep alerts into a tsv file for parsing
    cat "~{out_base}/~{out_base}.vadr.alt.list" | cut -f 2 | tail -n +2 > "~{out_base}.vadr.alerts.tsv"
    cat "~{out_base}.vadr.alerts.tsv" | wc -l > NUM_ALERTS

    read -r num < NUM_ALERTS
    if [[ "$num" -lt 1 ]]; then
      echo true > vadr.result
    else
     echo false > vadr.result
    fi

  >>>
  output {
    File feature_tbl  = "~{out_base}/~{out_base}.vadr.pass.tbl"
    Int  num_alerts = read_int("NUM_ALERTS")
    File alerts_list = "~{out_base}/~{out_base}.vadr.alt.list"
    Array[Array[String]] alerts = read_tsv("~{out_base}.vadr.alerts.tsv")
    File outputs_tgz = "~{out_base}.vadr.tar.gz"
    Boolean vadr_result = read_boolean("vadr.result")
  }
  runtime {
    docker: "~{docker}"
    memory: "64 GB"
    cpu: cpus
    dx_instance_type: "mem3_ssd1_v2_x8"
  }
}
