.data
    # Exemplo: var: .word 5
	vetor: .float 1.0, 1.5
	TAM: .word 2
	filename: .asciiz "output.txt"
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
    	l.s $f12, 0($s0)
    	
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
