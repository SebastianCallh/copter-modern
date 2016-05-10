import sys

#Splits labels from instructions on tabs, so the code must be indented using tabs
#Splits instruction from args using spaces, so they must be separated using spaces
#Only deals in hexadecimal numbers

#TODO
#mods
#fetch bit
#inst is actually op-code
#comments

# MV 10    -- Save the number 10 to PMEM(RES)
# MV &10   -- Save the number on memory location 10 to PMEM(RES)
# MV *10   -- Save the number that the address on memory location 10 points to to PMEM(RES)

#Valid code could be:
#START 	JMP 01
#	MV 12 *10
#END	DIE


def to_hex(n, s):
    return ('{0:0' + str(s) + 'x}').format(int(hex(int(n, 2)), 16))

FETCH_NEXT = '100000'
DONT_FETCH_NEXT = '00'
NO_OPERAND = '0000'

if not len(sys.argv) is 2:
    sys.exit('No code to assemble supplied')
    
op_code = {
    'MV'  : '01',
    'ADD' : '02',
    'SUB' : '03',
    'BEQ' : '04',
    'BNE' : '05',
    'BN'  : '06',
    'JMP' : '07',
    'LR'  : '08',
    'DIE' : 'FF'
    }
has_one_arg = ['ADD', 'SUB', 'BEQ', 'BNE', 'BN', 'JMP', 'LR']
has_two_args = ['MV']

lines = []
with open(sys.argv[1]) as f:
    lines = f.readlines()

line_nr = 0;
label_lookup = {}
instructions = ''

for line in lines:
    split_string = line.split('\t')
    label, op_and_args = split_string[0], split_string[1].split()
    op = op_and_args[0]
    machine_instr = ''

    #Don't create any mods if there are no args
    if len(split_string) is 2:
        args = op_and_args[1:] 
        mods = ['10' if arg[0] is '*' else 
                '01' if arg[0] is '&' else 
                '00' for arg in args]

    #remove prefixes
    args = [arg[1:] if not arg[0].isdigit() else arg for arg in args]
    
    #Save all labels' line number for jumps
    if label:
        label_lookup[label] = line_nr

    if op and op not in op_code:
        sys.exit("Unknown op-code \'{0}\' at line {1}".format(op, line_nr))

    print(op, mods, args)
    #Construct the final machine code instruction
    if op in has_one_arg or op in has_two_args:
        print(op_code[op], mods[0], FETCH_NEXT, bin(int(args[0]))[2:])
        instructions += op_code[op] + to_hex(mods[0] + FETCH_NEXT + bin(int(args[0]))[2:], 2) + '\n'
        if op in has_two_args:
            instructions += op_code[op] + to_hex(mods[0] + FETCH_NEXT, 2) + args[0] + '\n'
            instructions += op_code['LR'] + to_hex(mods[1] + FETCH_NEXT, 2) + args[1] + '\n'
            instructions += op_code['MV'] + to_hex('00' + FETCH_NEXT, 2) + NO_OPERAND + '\n'
    else:
        instructions += op_code[op] + to_hex('00' + DONT_FETCH_NEXT, 2) + NO_OPERAND + '\n'

    line_nr += 1

print(instructions)
f = open('machine_code','w')
f.write(instructions) 
f.close()
