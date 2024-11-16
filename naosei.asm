.data
    vetor: .double 123.45, 10.2, 1000.234, 666.66666
    TAM: .word 4
    filename: .asciiz "output.txt"
    string: .space 20          # Buffer para armazenar o float convertido em string
    string2: .space 100000 #string desenvertida
    const_100: .double 100.0

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
    
    la $a2, string2

loop_vetor:

    l.d $f12, 0($s0)             # Carrega o valor do vetor em $f12

    # Converte a parte inteira do float
    trunc.w.d $f0, $f12
    mfc1 $a1, $f0
    la $a0, string
    
#    li $t6, 0
    
int_to_string:
    li $t3, 35
    sb $t3, 0($a0) #coloca # no comeco da string para declarar que é o comeco
    addi $a0, $a0, 1

int_to_string_loop:
    li $t4, 10
    div $a1, $t4 #divide por 10
    mfhi $t3 #resto
    mflo $a1 #quociente
    
    addi $t3, $t3, 48 #ascii
    sb $t3, 0($a0)
    addi $a0, $a0, 1
    
    bnez $a1, int_to_string_loop #continua o loop enquanto o quociente for !=0
    
#    la $a2, string2
    j inverte_string

coloca_ponto:
    li $t4, 46
    sb $t4, 0($a2)
    addi $t6, $t6, 1
    addi $a2, $a2, 1
    
    
parte_fracionada:
    cvt.d.w $f0, $f0 #converte uma word para double, nao sei se é realmente necessário...
    sub.d $f2, $f12, $f0 #diminui a parte inteira e deixa só a parte fracionaria

    la $t7, const_100
    l.d $f10, 0($t7) #carrega o numero 100000.0 para a multiplicacao
    
    mul.d $f2, $f2, $f10 #multiplica
    
    trunc.w.d $f2, $f2
    mfc1 $a1, $f2
    
    li $t3, 42
    sb $t3, 0($a0) #coloca * no comeco da string para declarar que é o comeco da parte fracionaria

    addi $a0, $a0, 1
    
    loop_fracionada:
    li $t4, 10
    div $a1, $t4 #divide por 10
    mfhi $t3 #resto
    mflo $a1 #quociente
    
    addi $t3, $t3, 48 #ascii
    sb $t3, 0($a0)

    addi $a0, $a0, 1
    
    bnez $a1, loop_fracionada #continua o loop enquanto o quociente for !=0
    
#    la $a2, string2
    
inverte_string:
    subi $a0, $a0, 1
    lb $t4, 0($a0)
    
    beq $t4, 35, coloca_ponto #se o byte carregado for #, coloca ponto
    beq $t4, 42, proximo #se for *, finaliza
    
    sb $t4, 0($a2)
    addi $t6, $t6, 1
    addi $a2, $a2, 1
    
    j inverte_string
    
 proximo:
 
     li $t3, 10 #adiciona \n
    sb $t3, 0($a2)
    addi $t6, $t6, 1
    addi $a2, $a2, 1
    
#avança para o proximo valor do vetor
addi $t2, $t2, 1
addi $s0, $s0, 8
bne $t2, $t1, loop_vetor        # Verifica se atingiu o final do vetor

escreve_arquivo:

    
    
        # Syscall para escrever no arquivo
    li $v0, 15                    # Código de syscall para escrever
    move $a0, $t0                 # Descritor do arquivo em $a0
    la $a1, string2     # Endereço dos dados a serem escritos
    move $a2, $t6                  # Número de bytes a escrever
    syscall
    move $t0, $v0
    


fimloop:
    # Fecha o arquivo
    li $v0, 16
    move $a0, $t0
    syscall

    # Finaliza o programa
    li $v0, 10
    syscall
