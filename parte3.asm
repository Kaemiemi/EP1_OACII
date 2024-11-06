.data
    # Exemplo: var: .word 5
	vetor: .float 1.0, 1.5
	TAM: .word 2
	filename: .asciiz "output.txt"
	buffer: .space 20 #para armazenar o float como string
.text
.globl main
main:
#primeiro vou tentar pegar um número e imprimir ele em um arquivo =)
    li $v0, 13                  #abre um arquivo
    la $a0, filename
    li $a1, 1
    
    syscall
    move $t0, $v0
    
    la $s0, vetor               # Carrega o endereço base do vetor em $s0
    la $t1, TAM
    lw $t1, 0($t1) #carrega o tamanho do vetor
    li $t2, 0 #indice do veto (i)

#loop que passa pelo vetor
    loop:
    	beq $t2, $t1, fimloop #se chegou até o final do vetor
    	l.s $f12, 0($s0) #carrega o valor do vetor para f12
    	
    	#escrever para transformar o float em caracter aqui!
	trunc.w.s $f0, $f12 #trunca a parte inteira de f12
    	mfc1 $a1, $f0 #move a parte inteira para a1
    	
    	la $a0, buffer              # Buffer para armazenar a string
    	jal int_to_string   #chama função para converter para string
    	
    	li $v0, 15                  # Syscall para escrever float no arquivo
    	move $a0, $t0               # Descritor do arquivo em $a0
    	syscall
    	
    	addi $s0, $s0, 4            # Avança para o próximo elemento do vetor (4 bytes)
    	addi $t2, $t2, 1
    	
    	j loop
    	
    fimloop:
	li $v0, 16                  # Syscall para fechar arquivo
	move $a0, $t0               # Passa o descritor do arquivo
	syscall

    # Encerrar o programa
    li $v0, 10                  # Syscall para sair
    syscall
    
    int_to_string:
    # Salvar registradores que vamos usar
    addi $sp, $sp, -16          # Reserva espaço na pilha
    sw $t0, 0($sp)              # Salva $t0 (valor temporário)
    sw $t1, 4($sp)              # Salva $t1 (contagem de dígitos)
    sw $t2, 8($sp)              # Salva $t2 (registrador auxiliar)
    sw $ra, 12($sp)             # Salva $ra (endereço de retorno)

    # Verificar se o número é zero
    li $t1, 0                   # Inicializa contador de dígitos
    beq $a1, $zero, handle_zero # Se $a1 é zero, trata especialmente

convert_loop:
    # Extrair o dígito mais à direita
    li $t2, 10                  # Divisor 10
    div $a1, $t2                # Divide $a1 por 10
    mfhi $t0                    # Obtém o resto (dígito atual) em $t0
    mflo $a1                    # Atualiza $a1 para o quociente

    # Converter o dígito para ASCII
    addi $t0, $t0, 48           # Converte o dígito para ASCII ('0' é 48)

    # Armazenar o dígito no buffer (invertido)
    sub $t2, $t1, 0             # Posiciona $t0 no buffer invertido
    sb $t0, 0($a0)              # Salva o caractere ASCII no buffer
    addi $a0, $a0, 1            # Avança o ponteiro de string
    addi $t1, $t1, 1            # Incrementa a contagem de dígitos

    # Repetir se ainda restam dígitos
    bne $a1, $zero, convert_loop

    # Reverter o buffer (opcional)
reverse_buffer:
    sub $t1, $t1, 1

