

def initChannel():
    e = {}

    e['Fast_DAC'] = ''
    e['Fast_Hit_Readout'] = ''
    e['Fast_Powerdown'] = ''
    e['Fast_Trig_Enable'] = ''
    e['Feedback_Cap'] = ''
    e['Feedback_Resistor'] = ''
    e['Feedback_Type'] = ''
    e['Fet_Size'] = ''
    e['Follower'] = ''
    e['Gain'] = ''
    e['Polarity'] = ''
    e['Pole_Zero_Enable'] = ''
    e['Powerdown'] = ''
    e['Shaping_Time'] = ''
    e['Slow_DAC'] = ''
    e['Slow_Hit_Readout'] = ''
    e['Slow_Trig_Enable'] = ''
    e['Test_Enable'] = ''
    e['VRef'] = ''
    e['Board_Number'] = ''
    e['Channel_Number'] = ''
    e['Node_Number'] = ''
    e['Rena'] = ''
    e['Address'] = ''

    return e


def compChannel(b1, b2):
    if b1['Fast_DAC'] == b2['Fast_DAC'] and \
       b1['Fast_Hit_Readout'] == b2['Fast_Hit_Readout'] and \
       b1['Fast_Powerdown'] == b2['Fast_Powerdown'] and \
       b1['Fast_Trig_Enable'] == b2['Fast_Trig_Enable'] and \
       b1['Feedback_Cap'] == b2['Feedback_Cap'] and \
       b1['Feedback_Resistor'] == b2['Feedback_Resistor'] and \
       b1['Feedback_Type'] == b2['Feedback_Type'] and \
       b1['Fet_Size'] == b2['Fet_Size'] and \
       b1['Follower'] == b2['Follower'] and \
       b1['Gain'] == b2['Gain'] and \
       b1['Polarity'] == b2['Polarity'] and \
       b1['Pole_Zero_Enable'] == b2['Pole_Zero_Enable'] and \
       b1['Powerdown'] == b2['Powerdown'] and \
       b1['Shaping_Time'] == b2['Shaping_Time'] and \
       b1['Slow_DAC'] == b2['Slow_DAC'] and \
       b1['Slow_Hit_Readout'] == b2['Slow_Hit_Readout'] and \
       b1['Slow_Trig_Enable'] == b2['Slow_Trig_Enable'] and \
       b1['Test_Enable'] == b2['Test_Enable'] and \
       b1['VRef'] == b2['VRef']:

        return True
    else:
        return False


def initBoard():
    e = {}

    e['Force_Trig'] = ''
    e['OR_Mode'] = ''
    e['Readout_Enable'] = ''
    e['Selective_Read'] = ''
    e['Board_Number'] = ''
    e['Intermediate_Board'] = ''
    e['Node_Number'] = ''
    e['SerialNum']= ''
    e['Address'] = ''

    return e


def compBoard(b1, b2):
    if b1['Force_Trig']     == b2['Force_Trig'] and \
       b1['OR_Mode']        == b2['OR_Mode'] and \
       b1['Readout_Enable'] == b1['Readout_Enable'] and \
       b1['Selective_Read'] == b1['Selective_Read']:

        return True
    else:
        return False


def matchChannel(channels, channel):
    # Generate channel address
    n = int(channel['Node_Number'])
    b = int(channel['Board_Number'])
    r = int(channel['Rena'])
    c = int(channel['Channel_Number'])

    channel['Address'] = f'{n:01d}-{b:01d}-{r:01d}-{c:02d}'

    found = False

    #for c in channels:
    #    if compChannel(c,channel):
    #        c['Address'] += ', '
    #        c['Address'] += channel['Address']
    #        found = True
    #        break

    if not found:
        channels.append(channel)


def matchBoard(boards, board):
    # Generate channel address
    n = int(board['Node_Number'])
    b = int(board['Board_Number'])

    board['Address'] = f'{n}-{b}'

    found = False

    for b in boards:
        if compBoard(b,board):
            b['Address'] += ', '
            b['Address'] += board['Address']
            found = True
            break

    if not found:
        boards.append(board)


channels = []
boards = []

with open("old.cfg") as f:
    inChannel = False
    inBoard = False
    entry = None

    for line in f:

        data = line.strip()

        if data == 'Channel {':
            inChannel = True
            entry = initChannel()

        elif data == 'Board {':
            inBoard = True
            entry = initBoard()

        elif data == '}':
            if inChannel and entry['Node_Number'] == '1' and entry['Board_Number'] == '16':
                matchChannel(channels,entry)
            if inBoard:
                matchBoard(boards,entry)

            inChannel = False
            inBoard = False
            entry = None

        elif entry is not None:

            fields = data.split('=')

            if len(fields) == 2:
                entry[fields[0].strip()] = fields[1].strip()

schans = sorted(channels, key=lambda i: int(i['Rena']) * 100 + int(i['Channel_Number']))

for rena in range(2):
    print(f"        Rena[{rena}]:")

    for chan in schans:

        if int(chan['Rena']) == rena:
            print("          Channel[{}]:".format(chan['Channel_Number']))
            print("            FastDac: {}".format(chan['Fast_DAC']))
            print("            SlowDac: {}".format(chan['Slow_DAC']))
            print("            FastTrigEnable: " + ('Enable'   if chan['Fast_Trig_Enable'] == '1' else 'Disable'))
            print("            SlowTrigEnable: " + ('Enable'   if chan['Slow_Trig_Enable'] == '1' else 'Disable'))
            print("            Polarity: "       + ('Positive' if chan['Polarity'] == '1' else 'Negative'))

