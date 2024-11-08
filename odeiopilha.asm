.data
    vetor: .float 1.0, 1.5
    TAM: .word 2
    filename: .asciiz "output.txt"
    buffer: .space 20          # Buffer para armazenar o float convertido em string
    dot_char: .asciiz "."       # Caractere para ponto decimal
    const_10: .float 10.0       # Constante de 10.0 para multiplicação

.text
.globl main

main:
    # Abre o arquivo para escrita
    li $v0, 13
    la $a0, filename
    li $a1, 1
    syscall
    move $t0, $v0                # Guarda o descritor do arquivo em $t0

    # Carrega o endereço do vetor e o tamanho
    la $s0, vetor
    la $t1, TAM
    lw $t1, 0($t1)
    li $t2, 0                    # Índice do vetor

loop:
    beq $t2, $t1, fimloop        # Verifica se atingiu o final do vetor
    l.s $f12, 0($s0)             # Carrega o valor do vetor em $f12

    # Converte a parte inteira do float
    trunc.w.s $f0, $f12
    mfc1 $a1, $f0
    la $a0, buffer
    jal int_to_string            # Converte a parte inteira para string

    # Adiciona ponto decimal ao buffer
    la $a1, dot_char
    jal append_to_buffer

    # Converte a parte fracionária
    cvt.s.w $f1, $f0             # Converte a parte inteira para float
    sub.s $f2, $f12, $f1         # Calcula a parte fracionária
    li $t3, 3                    # Limite de casas decimais

decimal_loop:
    beqz $t3, write_to_file      # Verifica o limite de casas decimais
    l.s $f3, const_10            # Carrega 10.0
    mul.s $f2, $f2, $f3          # Multiplica a parte fracionária por 10
    trunc.w.s $f0, $f2
    mfc1 $a1, $f0
    jal int_to_string            # Converte o próximo dígito da parte fracionária
    cvt.s.w $f1, $f0
    sub.s $f2, $f2, $f1          # Calcula o próximo valor fracionário
    addi $t3, $t3, -1            # Decrementa o limite de casas decimais
    j decimal_loop

write_to_file:
    # Escreve o valor convertido no arquivo
    li $v0, 15
    move $a0, $t0
    la $a1, buffer
    syscall

    # Avança para o próximo valor do vetor
    addi $s0, $s0, 4
    addi $t2, $t2, 1
    j loop

fimloop:
    # Fecha o arquivo
    li $v0, 16
    move $a0, $t0
    syscall

    # Finaliza o programa
    li $v0, 10
    syscall

# Função int_to_string: Converte um inteiro em string
# Parâmetros: $a1 = inteiro, $a0 = endereço do buffer
int_to_string:
    addi $sp, $sp, -8
    sw $ra, 4($sp) #endereço de retorno
    sw $t0, 0($sp) #descritor

    move $t0, $a0
    li $t3, 0

    # Se o número é zero, escreve '0'
    beqz $a1, int_zero_case

int_to_string_loop:
    li $t4, 10
    div $a1, $t4 #divide por 10
    mfhi $t3 #resto
    mflo $a1 #quociente
    
    addi $t3, $t3, 48
    sb $t3, 0($t0)
    addi $t0, $t0, 1
    
        # Syscall para escrever no arquivo
    li $v0, 15                    # Código de syscall para escrever
    move $a0, $t0                 # Descritor do arquivo em $a0
    la $a1, data_to_write         # Endereço dos dados a serem escritos
    li $a2, 14                    # Número de bytes a escrever (exemplo: 14 bytes)
    syscall

    
 #   addi $t3, $t3, 1 sei la oq q isso aqui faz
    bnez $a1, int_to_string_loop #continua o loop enquanto o quociente for !=0
