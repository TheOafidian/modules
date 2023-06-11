
process METABULI_BUILD {
    tag 'build'
    label 'process_single'

    conda "bioconda::metabuli=1.0.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metabuli:1.0.0--pl5321hf1761c0_0':
        'biocontainers/metabuli:1.0.0--pl5321hf1761c0_0' }"

    input:
    path(genomes)
    path(acc2taxid)
    path(db)

    output:
    path "metabuli_db.tar.gz", emit: db
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args_lib = task.ext.args_lib ?: ''
    """
    ls $genomes > fastas.txt
    metabuli \\
        add-to-library \\
        fastas.txt \\
        $acc2taxid \\
        $db
        $args_lib

    ls $db/library > lib.txt
    metabuli \\
        build \\
        --threads $task.cpus \\
        $db \\
        lib.txt \\
        $acc2taxid \\
        $args
    
    mkdir metabuli_db
    mv $db/!(*y) metabuli_db
    tar -czf "${db}.tar.gz" metabuli_db

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metabuli: \$(metabuli | grep Version | sed 's/^metabuli Version: //';))
    END_VERSIONS
    """
}
