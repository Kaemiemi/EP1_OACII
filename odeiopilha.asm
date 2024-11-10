.data
    vetor: .double 123.45
    TAM: .word 2
    filename: .asciiz "output.txt"
    string: .space 20          # Buffer para armazenar o float convertido em string
    string2: .space 20 #string desenvertida
    const_10: .double 10.0
    zero: .double 0.0
    erro_msg: .asciiz "ERRO EM ALGUMA COISA.\n"

.text
.globl main

main:
    # Abre o arquivo para escrita
    li $v0, 13
    la $a0, filename
    li $a1, 1
    syscall
    move $t0, $v0 # Guarda o descritor do arquivo em $t0

    # Carrega o endereço do vetor e o tamanho
    la $s0, vetor
    la $t1, TAM
    lw $t1, 0($t1)
    li $t2, 0                    # Índice do vetor

loop_vetor:
    beq $t2, $t1, fimloop        # Verifica se atingiu o final do vetor
    l.d $f12, 0($s0)             # Carrega o valor do vetor em $f12

    # Converte a parte inteira do float
    trunc.w.d $f0, $f12
    mfc1 $a1, $f0
    la $a0, string
    
    
int_to_string:
#    move $t0, $a0
    li $t5, 0

    li $t3, 35
    sb $t3, 0($a0) #coloca # no comeco da string para declarar que é o comeco
    addi $t5, $t5, 1
    addi $a0, $a0, 1

int_to_string_loop:
    li $t4, 10
    div $a1, $t4 #divide por 10
    mfhi $t3 #resto
    mflo $a1 #quociente
    
    addi $t3, $t3, 48 #ascii
    sb $t3, 0($a0)
    addi $t5, $t5, 1 #numero de caracteres
    addi $a0, $a0, 1
    
    bnez $a1, int_to_string_loop #continua o loop enquanto o quociente for !=0
    
    
    la $a2, string2
    
inverte_string:
    subi $a0, $a0, 1
    lb $t4, 0($a0)
    
    beq $t4, 35, coloca_ponto #se o byte carregado for #, finaliza
    
    sb $t4, 0($a2)
    addi $a2, $a2, 1
    
    j inverte_string
    
coloca_ponto:
    addi $a2, $a2, 1
    li $t4, 46
    sb $t4, 0($a2)
    
parte_fracionada:

    sub.d $f2, $f12, $f0 #diminui a parte inteira e deixa só a parte fracionaria
    mfc1 $a0, $f2        # Move a parte fracionária para o registrador de uso geral
li $v0, 1             # Código de syscall para imprimir inteiro
syscall

    
    la $t7, const_10
    l.d $f10, 0($t7) #carrega o numero 10.0 para a multiplicacao
    
    la $t7, zero
    l.d $f8, 0($t7) #carrega 0.0 em f11 para fazer comparacao depois
    
    loop_fracionada: #passa por cada número e conta quantos números tem depois do ponto

    mul.d $f2, $f2, $f10 #multiplica valor por 10 e salva em f2
    trunc.w.d $f4, $f2
    mfc1 $t3, $f4
    
    move $a0, $t3
    li $v0, 1
    syscall
    
    addi $t3, $t3, 48 #ascii
    addi $a2, $a2, 1 #adiciona mais uma casa na string2 para salvarmos valor
    sb $t3, 0($a2)

    addi $t6, $t6, 1 #contador
    sub.d $f2, $f2, $f4
    
    
    
    c.eq.d $f2, $f8
    bc1t escreve_arquivo
    
    j loop_fracionada
    
#    beq $f2, escreve_arquivo
 
escreve_arquivo:
    add $t5, $t5, $t6 #t5 é a quantidade de bytes que preciso escrever, aqui estou somando t5+t6 pois t6 é o contador apenas da parte fracionaria
    addi $t5, $t5, 1  #aqui adiciona +1 por causa do ponto
#    subi $t5, $t5, 1  # Reduz o tamanho para não incluir `#`
    li $t3, 10
    sb $t3, 0($a2)
    
        # Syscall para escrever no arquivo
    li $v0, 15                    # Código de syscall para escrever
    move $a0, $t0                 # Descritor do arquivo em $a0
    la $a1, string2     # Endereço dos dados a serem escritos
    move $a2, $t5                   # Número de bytes a escrever
    syscall
    
#avança para o proximo valor do vetor
addi $t2, $t2, 1
addi $s0, $s0, 4
j loop_vetor

fimloop:
    # Fecha o arquivo
    li $v0, 16
    move $a0, $t0
    syscall

    # Finaliza o programa
    li $v0, 10
    syscall
