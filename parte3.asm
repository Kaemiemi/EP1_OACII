.data
    vetor: .double 123.45, 10.2, 1000.234, 666.66666
    TAM: .word 4                            # tamanho do vetor
    filename: .asciiz "output.txt"          # nome do arquivo
    buffer: .space 30                       # Buffer para armazenar o double convertido em char
    string: .space 1000000                  # string para armazenar o valor final não invertido
    arredondamento: .double 100.0           # Valor de arredondamento no arquivo, quantas casas depois da vígula

.text
.globl main

main:
    # Abre o arquivo para escrita
    li $v0, 13
    la $a0, filename 
    li $a1, 1                              # modo de leitura e escrita
    syscall
    move $t0, $v0                          # Guarda o descritor do arquivo em $t0

    # Carrega o endereço do vetor e o tamanho
    la $s0, vetor
    la $t1, TAM
    lw $t1, 0($t1)
    li $t2, 0                              # Índice do vetor
    
    la $a2, string

    # Loop que passa por cada elemento do vetor
    loop_vetor:
        l.d $f12, 0($s0)                   # Carrega o valor do vetor em $f12

        # Trunca a parte inteira do double
        trunc.w.d $f0, $f12
        mfc1 $a1, $f0
        la $a0, buffer                     # Declara o buffer auxiliar
    
    # Inicia a conversão para caracter
    int_to_string:
        li $t3, 35
        sb $t3, 0($a0)                     # Coloca # no comeco da string para declarar que é o comeco
        addi $a0, $a0, 1
	# Loop que separa cada dígito do número
        int_to_string_loop:
            li $t4, 10
            div $a1, $t4                   # divide por 10
            mfhi $t3                       # resto
            mflo $a1                       # quociente
    
            addi $t3, $t3, 48              # ASCII
            sb $t3, 0($a0)                 # Salva no buffer
            addi $a0, $a0, 1
    
            bnez $a1, int_to_string_loop   # continua o loop enquanto o quociente for !=0
    
            j inverte_string
            
    # Insere um ponto ao terminar a parte inteira
    coloca_ponto:
        li $t4, 46
        sb $t4, 0($a2)
        addi $t6, $t6, 1
        addi $a2, $a2, 1
    
    # Começa a lidar com as casas decimais
    parte_fracionada:
        cvt.d.w $f0, $f0                   # converte uma word para double, necessário...
        sub.d $f2, $f12, $f0               # diminui a parte inteira e deixa só a parte fracionaria

        la $t7, arredondamento
        l.d $f10, 0($t7)                   # carrega o numero 100.0 para a multiplicacao
    
        mul.d $f2, $f2, $f10               # multiplica por 100.0
    
        trunc.w.d $f2, $f2
        mfc1 $a1, $f2
    
        li $t3, 42
        sb $t3, 0($a0)                     # coloca * no comeco da string para declarar que é o comeco da parte fracionaria

        addi $a0, $a0, 1
    
            # Loop que separa cada dígito do número
            loop_fracionada:
                li $t4, 10
                div $a1, $t4               # divide por 10
                mfhi $t3                   # resto
                mflo $a1                   # quociente
    
                addi $t3, $t3, 48          # ASCII
                sb $t3, 0($a0)             # Salva no buffer

                addi $a0, $a0, 1
    
                bnez $a1, loop_fracionada  # continua o loop enquanto o quociente for !=0
    
    # Inverte o valor registrado no buffer e salva em string
    inverte_string:
        subi $a0, $a0, 1
        lb $t4, 0($a0)
    
        beq $t4, 35, coloca_ponto          # se o byte carregado for #, coloca ponto
        beq $t4, 42, proximo               # se for *, vai para o proximo numero do vetor
    
        sb $t4, 0($a2)
        addi $t6, $t6, 1
        addi $a2, $a2, 1
    
        j inverte_string
    
    proximo:
 
        li $t3, 10                          # Adiciona \n
        sb $t3, 0($a2)
        addi $t6, $t6, 1
        addi $a2, $a2, 1
    
        # Avança para o proximo valor do vetor
        addi $t2, $t2, 1
        addi $s0, $s0, 8
        bne $t2, $t1, loop_vetor            # Verifica se atingiu o final do vetor

    escreve_arquivo:
    
        # Syscall para escrever no arquivo
        li $v0, 15                          # Código de syscall para escrever
        move $a0, $t0                       # Descritor do arquivo em $a0
        la $a1, string                      # Endereço dos dados a serem escritos
        move $a2, $t6                       # Número de bytes a escrever
        syscall
        move $t0, $v0                       # Guarda descritor em t0
    


    fimloop:
        # Fecha o arquivo
        li $v0, 16
        move $a0, $t0                       # Salva descritor
        syscall

        # Finaliza o programa
        li $v0, 10
        syscall
