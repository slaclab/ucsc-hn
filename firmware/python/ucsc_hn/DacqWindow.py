#-----------------------------------------------------------------------------
# Title      : PyRogue PyDM Run Control Widget
#-----------------------------------------------------------------------------
# This file is part of the rogue software platform. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the rogue software platform, including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

from pydm.widgets.frame import PyDMFrame
from pydm.widgets import PyDMEnumComboBox, PyDMLabel, PyDMSpinbox, PyDMPushButton
from pyrogue.pydm.data_plugins.rogue_plugin import nodeFromAddress
from pyrogue.pydm.widgets import PyRogueLineEdit
from qtpy.QtCore import Qt
from qtpy.QtWidgets import QVBoxLayout, QHBoxLayout, QFormLayout, QGroupBox


class DacqWindow(PyDMFrame):
    def __init__(self, parent=None, init_channel=None):
        PyDMFrame.__init__(self, parent, init_channel)
        self._node = None

    def connection_changed(self, connected):
        build = (self._node is None) and (self._connected != connected and connected is True)
        super(DacqWindow, self).connection_changed(connected)

        if not build:
            return

        self._node = nodeFromAddress(self.channel)
        self._path = self.channel

        vb = QVBoxLayout()
        self.setLayout(vb)

        gb = QGroupBox('Edit Select') #Group 1
        vb.addWidget(gb)

        fl = QFormLayout()
        fl.setRowWrapPolicy(QFormLayout.DontWrapRows)
        fl.setFormAlignment(Qt.AlignHCenter | Qt.AlignTop)
        fl.setLabelAlignment(Qt.AlignRight)
        gb.setLayout(fl)

        w = PyDMSpinbox(parent=None, init_channel=self._path + '.NodeSelect')
        w.precision             = 0
        w.showUnits             = False
        w.precisionFromPV       = False
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = True
        w.showStepExponent      = False
        w.writeOnPress          = True

        fl.addRow('Node Number:',w)

        w = PyDMSpinbox(parent=None, init_channel=self._path + '.BoardSelect')
        w.precision             = 0
        w.showUnits             = False
        w.precisionFromPV       = False
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = True
        w.showStepExponent      = False
        w.writeOnPress          = True
        fl.addRow('Board Number:',w)

        hb = QHBoxLayout()
        vb.addLayout(hb)

        gb = QGroupBox('Board') # Group 2
        hb.addWidget(gb)

        fl = QFormLayout()
        fl.setRowWrapPolicy(QFormLayout.DontWrapRows)
        fl.setFormAlignment(Qt.AlignHCenter | Qt.AlignTop)
        fl.setLabelAlignment(Qt.AlignRight)
        gb.setLayout(fl)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.ReadoutEnable')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Serial Number:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.ForceTrig')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Readout Enable:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.OrMode')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Or Mode:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.SelectiveRead')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Selective Read:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.IntermediateBoard')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Intermediate Board:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.FollowerEn')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Force Trigger:',w)

        w = PyRogueLineEdit(parent=None, init_channel=self._path + '.FollowerAsic/disp')
        w.showUnits             = False
        w.precisionFromPV       = True
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = True
        fl.addRow('Link DAC Changes:',w)

        w = PyRogueLineEdit(parent=None, init_channel=self._path + '.FollowerChannel/disp')
        w.showUnits             = False
        w.precisionFromPV       = True
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = True
        fl.addRow('Follower Channel:',w)

        gb = QGroupBox('Channel Attributes') # Group 3
        hb.addWidget(gb)

        fl = QFormLayout()
        fl.setRowWrapPolicy(QFormLayout.DontWrapRows)
        fl.setFormAlignment(Qt.AlignHCenter | Qt.AlignTop)
        fl.setLabelAlignment(Qt.AlignRight)
        gb.setLayout(fl)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.FbResistor')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('RENA Number:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.TestInputEnable')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Fast DAC:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.FastChanPowerDown')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Slow DAC:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.FbType')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Slow Trig Enable:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.Gain')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Channel Power Down:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.PowerDown')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Channel Number:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.PoleZero')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Follower Mode:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.FbCapacitor')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Fast Trigger Enable:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.ShapeTime')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Fast Channel Power Down:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.FbFetSize')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Gain:',w)

        w = PyRogueLineEdit(parent=None, init_channel=self._path + '.FastDac/disp')
        w.showUnits             = False
        w.precisionFromPV       = True
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = True
        fl.addRow('Polarity:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.Polarity')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Vref:',w)

        w = PyRogueLineEdit(parent=None, init_channel=self._path + '.SlowDac/disp')
        w.showUnits             = False
        w.precisionFromPV       = True
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = True
        fl.addRow('POle-Zero:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.FastTrigEnable')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Feedback Capacity:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.SlowTrigEnable')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Feedback Resistor:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.SlowTrigEnable')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Test Input Enable:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.SlowTrigEnable')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('Feedback Type:',w)

        w = PyDMEnumComboBox(parent=None, init_channel=self._path + '.SlowTrigEnable')
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = False
        fl.addRow('FET Size:',w)

        gb = QGroupBox('Configuration') # Group 4
        vb.addWidget(gb)

        fl = QFormLayout()
        fl.setRowWrapPolicy(QFormLayout.DontWrapRows)
        fl.setFormAlignment(Qt.AlignHCenter | Qt.AlignTop)
        fl.setLabelAlignment(Qt.AlignRight)
        gb.setLayout(fl)

        w = PyDMSpinbox(parent=None, init_channel=self._path + '.NodeCopy')
        w.precision             = 0
        w.showUnits             = False
        w.precisionFromPV       = False
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = True
        w.showStepExponent      = False
        w.writeOnPress          = True

        fl.addRow('Copy Node:',w)

        w = PyDMSpinbox(parent=None, init_channel=self._path + '.BoardCopy')
        w.precision             = 0
        w.showUnits             = False
        w.precisionFromPV       = False
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = True
        w.showStepExponent      = False
        w.writeOnPress          = True
        fl.addRow('Copy Board:',w)

        w = PyDMSpinbox(parent=None, init_channel=self._path + '.RenaCopy')
        w.precision             = 0
        w.showUnits             = False
        w.precisionFromPV       = False
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = True
        w.showStepExponent      = False
        w.writeOnPress          = True
        fl.addRow('Copy Rena:',w)

        w = PyDMSpinbox(parent=None, init_channel=self._path + '.ChannelCopy')
        w.precision             = 0
        w.showUnits             = False
        w.precisionFromPV       = False
        w.alarmSensitiveContent = False
        w.alarmSensitiveBorder  = True
        w.showStepExponent      = False
        w.writeOnPress          = True
        fl.addRow('Copy Channel:',w)

        w = PyDMPushButton(label='Copy To',
                           pressValue=1,
                           init_channel=self._path + '.CopyChannelTo/disp')
        fl.addRow('Copy Channel:',w)

        w = PyDMPushButton(label='Copy From',
                           pressValue=1,
                           init_channel=self._path + '.CopyChannelFrom/disp')
        fl.addRow('Copy Channel:',w)

        w = PyDMPushButton(label='Copy To',
                           pressValue=1,
                           init_channel=self._path + '.CopyBoardTo/disp')
        fl.addRow('Copy Board:',w)

        w = PyDMPushButton(label='Copy From',
                           pressValue=1,
                           init_channel=self._path + '.CopyBoardFrom/disp')
        fl.addRow('Copy Board:',w)

