.data     
    # Nomes dos arquivos de dados
    xtrain_txt:             .asciiz "Xtrain.txt" 
    xtrain_array_chars:     .space 16384           
      
    xtest_txt:              .asciiz "Xtest.txt" 
    xtest_array_chars:      .space 16384         
      
    # Variáveis auxiliares para conversão
    newline_char:               .asciiz "/" 
      
    .align 2
    base_address_of_float_array: .word 0         
    partial_string:             .space 15
          
    xtrain_array_float:         .align 2
                               .space 4096    
    xtest_array_float:          .align 2
                               .space 4096             	               	     
  
    non_valid_float_value:      .float -999    # Indica o fim do array de floats	
    float_constant:             .float 0.0     
    float_ten:                  .float 10.0    
    float_hundred:              .float 100.0   
    float_thousand:             .float 1000.0  
         
    count_decimal_digits:       .word 0        # Quantidade de dígitos após o ponto decimal  
    index_of_period:            .word 0   
    
    # Para escrita no arquivo
#    TAM: .space 4                        # tamanho do vetor
    filename_xtrain: .asciiz "output_xtrain.txt"   # nome do arquivo
    filename_xtest: .asciiz "output_xtest.txt"    # nome do arquivo
    buffer: .space 30                       # Buffer para armazenar o double convertido em char
    string: .space 1000000                  # string para armazenar o valor final não invertido
    arredondamento: .float 100.0           # Valor de arredondamento no arquivo, quantas casas depois da vígula
    
.text
.globl main

main:
    # LEITURA 
    
    # 'xtrain.txt'
    la $a0, xtrain_txt
    la $a3, xtrain_array_chars 
    jal read_txt                               
    # 'xtest.txt'
    la $a0, xtest_txt
    la $a3, xtest_array_chars 
    jal read_txt                                   
    
    # CONVERSÃO 
    
    # 'xtrain_array_chars' para 'xtrain_array_float'
    la $t1, xtrain_array_chars
    la $a2, xtrain_array_float 
    sw $a2, base_address_of_float_array
    jal convert_partial_string_to_float  
    # 'xtest_array_chars' para 'xtest_array_float'
    la $t1, xtest_array_chars
    la $a2, xtest_array_float
    sw $a2, base_address_of_float_array
    jal convert_partial_string_to_float
    
    # Faz escrita em arquivo de xtrain
    la $a0, filename_xtrain            # Nome do arquivo "output_xtrain.txt"
    la $s0, xtrain_array_float
    jal escrita_em_arquivo
     
    li $v0, 10                  
    syscall


####### FUNÇÃO - LER ARQUIVO DE TEXTO 
read_txt: 
    li $v0, 13           # syscall 13 (abrir arquivo)
    li $a1, 0            # Modo somente leitura
    li $a2, 0            # Permissões do arquivo (ignoradas)
    syscall
      
    move $s0, $v0
     
    li $v0, 14           # syscall 14 (ler arquivo)
    move $a0, $s0        # descritor de arquivo
    move $a1, $a3
    li $a2, 16384
    syscall
  
    # Adiciona terminador nulo na string copiada  
    addi $t0, $a1, 16383 # 16384 - 1
    sb $zero, ($t0)      # Adiciona terminador nulo no final
      
    # Fecha o arquivo
    li $v0, 16          # syscall 16 (fechar arquivo)
    syscall
   
    # Limpa registradores
    move $t0, $zero 
    move $v0, $zero
    move $s0, $zero   
    move $a0, $zero  
    move $a1, $zero
    move $a3, $zero 		
  
    jr $ra		

####### FUNÇÃO - CONVERTER STRING PARA FLOAT
convert_partial_string_to_float:
    # Inicializa variáveis
    li $t0, 0                         # Contador de loop
    
fill_train_array_float_loop:
    li $t2, 0                         # Índice 'partial_string[]'
    li $t3, 0                         # Armazena cada char
    li $t4, 0                         # Armazena código ASCII
    li $t5, 0                         # Armazena código ASCII  
    
#### CRIA 'partial_string'    
    # Loop para criar o array 'partial_string' 	
loop_get_chars_to_partial_string:    # Loop para criar o array 'partial_string'   
    lb $t3, ($t1)                     # Carrega um caractere do array de caracteres   
        
    # Verifica fim do número                  
    beq $t3, 0x2C, format_partial_string      # Verifica: vírgula (',') 
    beq $t3, 0x00, format_partial_string      # Verifica: terminador nulo ('\0')
    beq $t3, 0xA, format_partial_string       # Verifica: nova linha  ('\n')
       
    # Verifica se é dígito decimal
    li $t4, 48                                # Código ASCII para '0'
    blt $t3, $t4, check_period                # Se menor que '0'   
    li $t5, 57                                # Código ASCII para '9'
    bgt $t3, $t5, check_period                # Se maior que '9'
     
    # Verifica se é ponto decimal
check_period:
    li $t4, 46                                # Código ASCII para ponto ('.')
    beq $t3, $t4, decimal_or_period 
  
    # É um dígito decimal ou ponto
decimal_or_period:
    sb $t3, partial_string($t2)               # Adiciona caractere em 'partial_string'
    addi $t1, $t1, 1                          # Incrementa índice do array de caracteres
    addi $t2, $t2, 1                          # Incrementa índice de 'partial_string'
    j loop_get_chars_to_partial_string  
                          
format_partial_string:
    # Adiciona terminador nulo no final de 'partial_string'   
    sb $zero, partial_string($t2)
     
    # Decrementa o índice para apontar para o último dígito válido                                  
    subi $t2, $t2, 1                                  
     
    addi $t1, $t1, 1                          # Incrementa índice do array de caracteres para o próximo loop                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
     
    # Limpa registradores	     
    move $t3, $zero                           # Limpa último char
    move $t4, $zero
    move $t5, $zero 
      
    j process_partial_string	

####### CONVERTE 'partial_string' PARA FLOAT  
process_partial_string:    
    # Inicializa variáveis    
    li $t3, 0
    li $t5, 0
    li $t6, 0  
    li $t7, 0                                      # Índice para 'adjust_format_float'
    li $t8, 0
    l.s $f2, float_constant 
    add.s $f0, $f0, $f2
          
    add $t6, $t6, $t2                              # Copia índice de 'partial_string[]' de $t2   
     
    # Verifica se há parte decimal - procura por '.'
check_decimal_part:                                                  
    lb $t8, partial_string($t6)
     
    li $t4, 46                                                  # Código ASCII para ponto ('.')
    beq $t8, $t4, decimal_part_create_float                     # Se encontrar '.', tem parte decimal  
     
    subi $t6, $t6, 1                                            # Decrementa índice      
    blt $t6, $zero, integer_part_create_float_NO_decimals       # Evita índice inválido 
    j check_decimal_part     
    
#### Cria parte decimal do float
    # Conta quantos dígitos decimais  
decimal_part_create_float:    
    sub $t8, $t2, $t6                              # Total_Decimal_Digits = (último índice - índice do ponto) 
    la $a0, index_of_period                        # Salva posição do índice do ponto 
    sw $t6, 0($a0)
      
    la $a0, count_decimal_digits                   # Salva a contagem na variável      
    sw $t8, 0($a0)    
    
    # Divide por 10  
    addi $t6, $t6, 1                               # Índice para o primeiro dígito decimal
      
    lb $t3, partial_string($t6)                    # Pega o primeiro dígito decimal    
    sub $t3, $t3, 48                               # Converte de ASCII para inteiro    
    mtc1 $t3, $f1     	            # Move inteiro para registrador float
    cvt.s.w $f1, $f1                               # Converte para float   
         
    l.s $f2, float_ten                            	
    div.s $f1, $f1, $f2                
    add.s $f0, $f0, $f1                            # Soma ao resultado final   
    
    # Verifica se há mais dígitos decimais para converter
    subi $t8, $t8, 1
    beqz $t8, integer_part_create_float_WITH_decimals
                        
    # Divide por 100   
    addi $t6, $t6, 1                               # Índice para o segundo dígito decimal
    lb $t5, partial_string($t6)                     
    sub $t5, $t5, 48                               # Converte de ASCII para inteiro    
    mtc1 $t5, $f1     	            # Move inteiro para registrador float
    cvt.s.w $f1, $f1                               # Converte para float                                                                                                          
     
    l.s $f2, float_hundred                               	
    div.s $f1, $f1, $f2                  
    add.s $f0, $f0, $f1
     
    # Verifica se há mais dígitos decimais para converter
    subi $t8, $t8, 1
    beqz $t8, integer_part_create_float_WITH_decimals
      
    # Divide por 1000  
    addi $t6, $t6, 1                               # Índice para o terceiro dígito decimal
    lb $t5, partial_string($t6)                     
    sub $t5, $t5, 48                               # Converte de ASCII para inteiro    
    mtc1 $t5, $f1     	            # Move inteiro para registrador float
    cvt.s.w $f1, $f1                               # Converte para float                                                                                                          
     
    l.s $f2, float_thousand                              	
    div.s $f1, $f1, $f2                  
    add.s $f0, $f0, $f1
                                                                                                                                                                                                                                                                                                  
    j integer_part_create_float_WITH_decimals  

###### Cria parte inteira do float                                                                
integer_part_create_float_NO_decimals:        
    add $t6, $t2, $zero                         
    j integer_part_create_float               

integer_part_create_float_WITH_decimals:   
    la $t8, index_of_period                   # Obtém índice do ponto decimal 
    lw $t6, 0($t8)              
    
    subi $t6, $t6, 1                          # Índice do primeiro dígito inteiro = (índice do ponto - 1)
      
    # Pega o primeiro dígito inteiro
integer_part_create_float:
    blt $t6, $zero, exit_convert_partial_string_to_float     # Verifica se o índice é válido (índice >= 0)     
    
    lb $t5, partial_string($t6)	           # Pega o dígito
    sub $t5, $t5, 48                          # Converte de ASCII para inteiro    
    mtc1 $t5, $f1     	           # Move inteiro para registrador float
    cvt.s.w $f1, $f1                          # Converte para float                                                                                                        
                                	
    add.s $f0, $f0, $f1                       # Soma ao resultado final    
    
    subi $t6, $t6, 1	                      # Ajusta índice para o próximo dígito
      
    blt $t6, $zero, exit_convert_partial_string_to_float     # Verifica se o índice é válido (índice >= 0)
    
    # Pega o segundo dígito inteiro - Multiplica por 10  
    lb $t5, partial_string($t6)	          
    sub $t5, $t5, 48                         
    mtc1 $t5, $f1     	          
    cvt.s.w $f1, $f1                                                                                                          
     
    l.s $f2, float_ten                              	
    mul.s $f1, $f1, $f2                  
    add.s $f0, $f0, $f1
     
    subi $t6, $t6, 1	                      # Ajusta índice para o próximo dígito
    blt $t6, $zero, exit_convert_partial_string_to_float     # Verifica se o índice é válido (índice >= 0) 
      
    # Pega o terceiro dígito inteiro - Multiplica por 100   
    lb $t5, partial_string($t6)	          
    sub $t5, $t5, 48                             
    mtc1 $t5, $f1     	          
    cvt.s.w $f1, $f1                                                                                                          
     
    l.s $f2, float_hundred                              	
    mul.s $f1, $f1, $f2                  
    add.s $f0, $f0, $f1
     
    subi $t6, $t6, 1	                      # Ajusta índice para o próximo dígito
    blt $t6, $zero, exit_convert_partial_string_to_float     # Verifica se o índice é válido (índice >= 0) 
       
exit_convert_partial_string_to_float:                             
    # Limpa o array 'partial_string' (define cada elemento como terminador nulo)
    la $t2, partial_string              # Carrega o endereço base de 'partial_string'                      
           
clear_loop:
    sb $zero, 0($t2)                    # Armazena terminador nulo no elemento atual
    addi $t2, $t2, 1                    # Avança para o próximo elemento
      
    lb  $t4, 0($t2) 
    bnez $t4, clear_loop                # Continua até encontrar terminador nulo                                       
                 
##### PREENCHE O ARRAY DE FLOAT 
    # Armazena o float no array
    lw $t9, base_address_of_float_array  # Carrega o endereço base do array de floats
    s.s $f0, 0($t9)                      # Armazena o float no array
    addi $t9, $t9, 4                     # Incrementa o endereço para o próximo float
    sw $t9, base_address_of_float_array  # Atualiza o endereço base
                      
    # Limpa o registrador $f0 para o próximo float    
    l.s $f0, float_constant                       
    
    # Verifica se chegou ao fim do array de caracteres
    lb $t3, ($t1)
    bnez $t3, fill_train_array_float_loop  # Se não for zero, continua o loop
    
    # Inclui valor não válido na última posição válida do array de floats  
    lw $t9, base_address_of_float_array    # Carrega o endereço base atualizado
    l.s $f0, non_valid_float_value 
    s.s $f0, 0($t9)                        # Armazena o valor sentinela no array
     
    # Limpa registradores
    l.s $f0, float_constant
    l.s $f1, float_constant
    l.s $f2, float_constant
        
    move $a0, $zero
    move $a1, $zero
    move $a2, $zero
    move $a3, $zero
        
    move $t0, $zero
    move $t1, $zero   
    move $t2, $zero                            
    move $t3, $zero                                  
    move $t4, $zero                                  
    move $t5, $zero                                  
    move $t6, $zero
    move $t7, $zero
    move $t8, $zero  
    move $t9, $zero                                   
          
    jr $ra

# Aqui inicia a Parte 3 - Escrita em arquivo
escrita_em_arquivo:
    # Cria arquivo xtrain para escrita
    li $v0, 13
    li $a1, 1                              # modo de leitura e escrita
    syscall
    move $t0, $v0                          # Guarda o descritor do arquivo em $t0

    # Carrega o endereço do vetor e o tamanho
#    la $t1, TAM
 #   lw $t1, 0($t1)
#    li $t2, 0                              # Índice do vetor

    li $t6, 0
    
    la $a2, string

    # Loop que passa por cada elemento do vetor
    loop_vetor:
        l.s $f12, 0($s0)                   # Carrega o valor do vetor em $f12
	
	la $s1, non_valid_float_value
	l.s $f0, 0($s1)
	c.eq.d $f12, $f0           # Se f12 for -999, significa que chegamos no final do vetor
	bc1t fimloop
	
        # Trunca a parte inteira do double
        trunc.w.s $f0, $f12
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
        cvt.s.w $f0, $f0                   # converte uma word para double, necessário...
        sub.s $f2, $f12, $f0               # diminui a parte inteira e deixa só a parte fracionaria

        la $t7, arredondamento
        l.s $f10, 0($t7)                   # carrega o numero 100.0 para a multiplicacao
    
        mul.s $f2, $f2, $f10               # multiplica por 100.0
    
        trunc.w.s $f2, $f2
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
#        addi $t2, $t2, 1
        addi $s0, $s0, 4
#        bne $t2, $t1, loop_vetor            # Verifica se atingiu o final do vetor
	j loop_vetor

    escrita:
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
	
	# Finaliza
        jr $ra
