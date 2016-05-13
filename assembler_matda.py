import sys
import copy

#Splits labels from instructions on tabs, so the code must be indented using tabs
#Splits instruction from args using spaces, so they must be separated using spaces
#Comments can be made by separating them fro mteh code via one or several spaces
#Only deals in hexadecimal numbers
#Can only jump backwards using labels

# MV 10    -- Save the number 10 to PMEM(RES)
# MV &10   -- Save the number on memory location 10 to PMEM(RES)
# MV *10   -- Save the number that the address on memory location 10 points to to PMEM(RES)

#Valid code could be:
#START 	JMP 01      #comment
#	MV 12 *10
#END	DIE


def to_hex(n, s):
    return ('{0:0' + str(s) + 'x}').format(int(hex(int(n, 2)), 16))

def to_bin(n, s):
    return format(int(n), '0' + str(s) + 'b')

def make_instr(i):
    return 'x\"' + str(i) + '",\n'

FETCH_NEXT = '100000'
DONT_FETCH_NEXT = '00'
NO_ARGS = '0000'
EMPTY_INSTR = '0000'

if not len(sys.argv) is 2:
    sys.exit('No code to assemble supplied')
    
op_code = {
    'MV'  : '16',
    'ADD' : '17',
    'SUB' : '1B',
    'BEQ' : '1F',
    'BNE' : '21',
    'BN'  : '23',
    'JMP' : '33',
    'RES' : '34',
    'NOT' : '25',
    'AND' : '27',
    'OR' : '2B',
    'XOR' : '2F',
    'ALU' : '35',
    'UPD' : '36',
    'RAN' : '3B',
    'INC' : '3C',
    'CMP' : '40',
    'DEC' : '43',
    'SRET': '',
    'TRET' : '',
    'CRET' : '',
    'RRET' : '',
    'TRET' : '',
    'DIE' : 'FF'
    }
has_one_arg = ['BEQ', 'BNE', 'BN', 'JMP', 'RES', 'INC', 'DEC', 'RAN']
has_two_args = ['MV', 'ADD', 'SUB', 'NOT', 'OR', 'XOR',  'CMP', 'AND' ]
prefixes = ['&', '*']

lines = []
lines_cp = []
with open(sys.argv[1]) as f:
    lines = f.readlines()
 
line_nr = 0;
labels = {}
instructions = ''

lines_cp = copy.deepcopy(lines)

# Get all labels numbered correctly
for line_ in lines_cp:
    split_str = line_.split('\t')
    label = split_str[0]

    if label:
        labels[label.replace('\n', '')] = str(line_nr)

    if len(split_str) == 1:
        line_nr += 1
        continue

    op_and_args = split_str[1].split()
    op = op_and_args[0]

    if op in has_one_arg or op in has_two_args:
        if op in has_two_args:
            line_nr += 2
        line_nr +=2
    else:
        line_nr += 1


# Convert assembly to machine code
for line in lines:
    split_string = line.split('\t')
    

    if len(split_string) == 1:
        instructions += make_instr(EMPTY_INSTR)
        continue

    op_and_args = split_string[1].split()
    op = op_and_args[0]
    machine_instr = ''

    if op and op not in op_code:
        sys.exit('Unknown op-code \'{0}\' at line {1}'.format(op, line_nr))

    #Don't create any mods if there are no args
    if len(split_string) >= 2:
        args = op_and_args[1:] 
        mods = ['10' if arg[0] is '*' else 
                '01' if arg[0] is '&' else 
                '00' for arg in args]

    #remove prefixes
    args = [arg[1:] if arg[0] in prefixes else arg for arg in args]

    #replace labels with line numbers
    args = [labels[arg] if arg in labels else arg for arg in args]

    #Construct the final machine code instruction
    if op in has_one_arg or op in has_two_args:
        if op in has_two_args:
            instructions += make_instr(op_code['RES'] + to_hex(mods[1] + FETCH_NEXT, 2))
            instructions += make_instr(to_hex(to_bin(args[1], 16), 4))
        instructions += make_instr(op_code[op] + to_hex(mods[0] + FETCH_NEXT, 2))
        instructions += make_instr(to_hex(to_bin(args[0], 16), 4))
    else:
        instructions += make_instr(op_code[op] + to_hex('00' + DONT_FETCH_NEXT, 2))




f = open('machine_code','w')
f.write(instructions) 
f.close()
