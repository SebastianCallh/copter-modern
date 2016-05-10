import sys

#Splits labels from instructions on tabs, so the code must be indented using tabs
#Splits instruction from args using spaces, so they must be separated using spaces
#Only deals in hexadecimal numbers

#TODO
#mods
#fetch bit
#inst is actually op-code
#comments

#Valid code could be:
#START 	NOP
#	MV 12 10
#END	DIE

if not len(sys.argv) is 2:
    sys.exit('No code to assemble supplied')
    
op_code_lookup = {'NOP' : '00',
                'MV'  : '01',
                'ADD' : '02',
                'SUB' : '03',
                'BEQ' : '04',
                'BNE' : '05',
                'BN'  : '06',
                'JMP' : '07',
                'DIE' : 'FF'}
has_one_arg = ['ADD', 'SUB', 'BEQ', 'BNE', 'BN']
has_two_args = ['MV']

lines = []
with open(sys.argv[1]) as f:
    lines = f.readlines()

line_nr = 0;
label_lookup = {}
instructions = ''

for line in lines:
    split_string = line.split('\t')
    label, whole_instr = split_string[0], split_string[1].split()
    instr = whole_instr[0]
    args = whole_instr[1:] 
    machine_instr = ''

    #Save all labels' line number for jumps
    if label:
        label_lookup[label] = line_nr

    if (instr):
        if instr not in op_code_lookup:
            sys.exit("Unknown instruction \'{0}\' at line {1}".format(instr, line_nr))

    #Construct the final machine code instruction
    machine_instr += op_code_lookup[instr]
    if instr in has_one_arg:
        machine_instr += args[0]
    elif instr in has_two_args:
        machine_instr += args[0]
        machine_instr += args[1]

    machine_instr += '\n'
    instructions += machine_instr
    line_nr += 1

f = open('machine_code','w')
f.write(instructions) 
f.close() 
