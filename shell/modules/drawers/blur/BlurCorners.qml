import QtQuick
import Quickshell

Region {
    required property string vAnchor
    required property string hAnchor
    required property int blurQuality
    required property real inLeft
    required property real inRight
    required property real inTop
    required property real inBottom
    required property real rTop
    required property real rBottom
    required property real rLeft
    required property real rRight

    property int steps: Math.max(1, blurQuality)
    function getM(i) { return Math.ceil(i * steps / 100); }
    function isActive(i) { return getM(i) > getM(i - 1); }
    function getYo(i) { return getM(i) / steps; }
    function getXVal(i) { return Math.sqrt(1 - Math.pow(getYo(i), 2)); }

    // Outer corner radii (only non-zero if both adjacent edges are rounded)
    property real rTL: Math.min(rTop, rLeft)
    property real rTR: Math.min(rTop, rRight)
    property real rBL: Math.min(rBottom, rLeft)
    property real rBR: Math.min(rBottom, rRight)

    // Top-Left Outer Corner
    Region { x: isActive(1) ? inLeft - rTL * getXVal(1) + 1 : 0; y: isActive(1) ? inTop - rTL * getYo(1) : 0; width: isActive(1) ? rTL * getXVal(1) : 0; height: isActive(1) ? rTL * getYo(1) : 0 }
    Region { x: isActive(2) ? inLeft - rTL * getXVal(2) + 1 : 0; y: isActive(2) ? inTop - rTL * getYo(2) : 0; width: isActive(2) ? rTL * getXVal(2) : 0; height: isActive(2) ? rTL * getYo(2) : 0 }
    Region { x: isActive(3) ? inLeft - rTL * getXVal(3) + 1 : 0; y: isActive(3) ? inTop - rTL * getYo(3) : 0; width: isActive(3) ? rTL * getXVal(3) : 0; height: isActive(3) ? rTL * getYo(3) : 0 }
    Region { x: isActive(4) ? inLeft - rTL * getXVal(4) + 1 : 0; y: isActive(4) ? inTop - rTL * getYo(4) : 0; width: isActive(4) ? rTL * getXVal(4) : 0; height: isActive(4) ? rTL * getYo(4) : 0 }
    Region { x: isActive(5) ? inLeft - rTL * getXVal(5) + 1 : 0; y: isActive(5) ? inTop - rTL * getYo(5) : 0; width: isActive(5) ? rTL * getXVal(5) : 0; height: isActive(5) ? rTL * getYo(5) : 0 }
    Region { x: isActive(6) ? inLeft - rTL * getXVal(6) + 1 : 0; y: isActive(6) ? inTop - rTL * getYo(6) : 0; width: isActive(6) ? rTL * getXVal(6) : 0; height: isActive(6) ? rTL * getYo(6) : 0 }
    Region { x: isActive(7) ? inLeft - rTL * getXVal(7) + 1 : 0; y: isActive(7) ? inTop - rTL * getYo(7) : 0; width: isActive(7) ? rTL * getXVal(7) : 0; height: isActive(7) ? rTL * getYo(7) : 0 }
    Region { x: isActive(8) ? inLeft - rTL * getXVal(8) + 1 : 0; y: isActive(8) ? inTop - rTL * getYo(8) : 0; width: isActive(8) ? rTL * getXVal(8) : 0; height: isActive(8) ? rTL * getYo(8) : 0 }
    Region { x: isActive(9) ? inLeft - rTL * getXVal(9) + 1 : 0; y: isActive(9) ? inTop - rTL * getYo(9) : 0; width: isActive(9) ? rTL * getXVal(9) : 0; height: isActive(9) ? rTL * getYo(9) : 0 }
    Region { x: isActive(10) ? inLeft - rTL * getXVal(10) + 1 : 0; y: isActive(10) ? inTop - rTL * getYo(10) : 0; width: isActive(10) ? rTL * getXVal(10) : 0; height: isActive(10) ? rTL * getYo(10) : 0 }
    Region { x: isActive(11) ? inLeft - rTL * getXVal(11) + 1 : 0; y: isActive(11) ? inTop - rTL * getYo(11) : 0; width: isActive(11) ? rTL * getXVal(11) : 0; height: isActive(11) ? rTL * getYo(11) : 0 }
    Region { x: isActive(12) ? inLeft - rTL * getXVal(12) + 1 : 0; y: isActive(12) ? inTop - rTL * getYo(12) : 0; width: isActive(12) ? rTL * getXVal(12) : 0; height: isActive(12) ? rTL * getYo(12) : 0 }
    Region { x: isActive(13) ? inLeft - rTL * getXVal(13) + 1 : 0; y: isActive(13) ? inTop - rTL * getYo(13) : 0; width: isActive(13) ? rTL * getXVal(13) : 0; height: isActive(13) ? rTL * getYo(13) : 0 }
    Region { x: isActive(14) ? inLeft - rTL * getXVal(14) + 1 : 0; y: isActive(14) ? inTop - rTL * getYo(14) : 0; width: isActive(14) ? rTL * getXVal(14) : 0; height: isActive(14) ? rTL * getYo(14) : 0 }
    Region { x: isActive(15) ? inLeft - rTL * getXVal(15) + 1 : 0; y: isActive(15) ? inTop - rTL * getYo(15) : 0; width: isActive(15) ? rTL * getXVal(15) : 0; height: isActive(15) ? rTL * getYo(15) : 0 }
    Region { x: isActive(16) ? inLeft - rTL * getXVal(16) + 1 : 0; y: isActive(16) ? inTop - rTL * getYo(16) : 0; width: isActive(16) ? rTL * getXVal(16) : 0; height: isActive(16) ? rTL * getYo(16) : 0 }
    Region { x: isActive(17) ? inLeft - rTL * getXVal(17) + 1 : 0; y: isActive(17) ? inTop - rTL * getYo(17) : 0; width: isActive(17) ? rTL * getXVal(17) : 0; height: isActive(17) ? rTL * getYo(17) : 0 }
    Region { x: isActive(18) ? inLeft - rTL * getXVal(18) + 1 : 0; y: isActive(18) ? inTop - rTL * getYo(18) : 0; width: isActive(18) ? rTL * getXVal(18) : 0; height: isActive(18) ? rTL * getYo(18) : 0 }
    Region { x: isActive(19) ? inLeft - rTL * getXVal(19) + 1 : 0; y: isActive(19) ? inTop - rTL * getYo(19) : 0; width: isActive(19) ? rTL * getXVal(19) : 0; height: isActive(19) ? rTL * getYo(19) : 0 }
    Region { x: isActive(20) ? inLeft - rTL * getXVal(20) + 1 : 0; y: isActive(20) ? inTop - rTL * getYo(20) : 0; width: isActive(20) ? rTL * getXVal(20) : 0; height: isActive(20) ? rTL * getYo(20) : 0 }
    Region { x: isActive(21) ? inLeft - rTL * getXVal(21) + 1 : 0; y: isActive(21) ? inTop - rTL * getYo(21) : 0; width: isActive(21) ? rTL * getXVal(21) : 0; height: isActive(21) ? rTL * getYo(21) : 0 }
    Region { x: isActive(22) ? inLeft - rTL * getXVal(22) + 1 : 0; y: isActive(22) ? inTop - rTL * getYo(22) : 0; width: isActive(22) ? rTL * getXVal(22) : 0; height: isActive(22) ? rTL * getYo(22) : 0 }
    Region { x: isActive(23) ? inLeft - rTL * getXVal(23) + 1 : 0; y: isActive(23) ? inTop - rTL * getYo(23) : 0; width: isActive(23) ? rTL * getXVal(23) : 0; height: isActive(23) ? rTL * getYo(23) : 0 }
    Region { x: isActive(24) ? inLeft - rTL * getXVal(24) + 1 : 0; y: isActive(24) ? inTop - rTL * getYo(24) : 0; width: isActive(24) ? rTL * getXVal(24) : 0; height: isActive(24) ? rTL * getYo(24) : 0 }
    Region { x: isActive(25) ? inLeft - rTL * getXVal(25) + 1 : 0; y: isActive(25) ? inTop - rTL * getYo(25) : 0; width: isActive(25) ? rTL * getXVal(25) : 0; height: isActive(25) ? rTL * getYo(25) : 0 }
    Region { x: isActive(26) ? inLeft - rTL * getXVal(26) + 1 : 0; y: isActive(26) ? inTop - rTL * getYo(26) : 0; width: isActive(26) ? rTL * getXVal(26) : 0; height: isActive(26) ? rTL * getYo(26) : 0 }
    Region { x: isActive(27) ? inLeft - rTL * getXVal(27) + 1 : 0; y: isActive(27) ? inTop - rTL * getYo(27) : 0; width: isActive(27) ? rTL * getXVal(27) : 0; height: isActive(27) ? rTL * getYo(27) : 0 }
    Region { x: isActive(28) ? inLeft - rTL * getXVal(28) + 1 : 0; y: isActive(28) ? inTop - rTL * getYo(28) : 0; width: isActive(28) ? rTL * getXVal(28) : 0; height: isActive(28) ? rTL * getYo(28) : 0 }
    Region { x: isActive(29) ? inLeft - rTL * getXVal(29) + 1 : 0; y: isActive(29) ? inTop - rTL * getYo(29) : 0; width: isActive(29) ? rTL * getXVal(29) : 0; height: isActive(29) ? rTL * getYo(29) : 0 }
    Region { x: isActive(30) ? inLeft - rTL * getXVal(30) + 1 : 0; y: isActive(30) ? inTop - rTL * getYo(30) : 0; width: isActive(30) ? rTL * getXVal(30) : 0; height: isActive(30) ? rTL * getYo(30) : 0 }
    Region { x: isActive(31) ? inLeft - rTL * getXVal(31) + 1 : 0; y: isActive(31) ? inTop - rTL * getYo(31) : 0; width: isActive(31) ? rTL * getXVal(31) : 0; height: isActive(31) ? rTL * getYo(31) : 0 }
    Region { x: isActive(32) ? inLeft - rTL * getXVal(32) + 1 : 0; y: isActive(32) ? inTop - rTL * getYo(32) : 0; width: isActive(32) ? rTL * getXVal(32) : 0; height: isActive(32) ? rTL * getYo(32) : 0 }
    Region { x: isActive(33) ? inLeft - rTL * getXVal(33) + 1 : 0; y: isActive(33) ? inTop - rTL * getYo(33) : 0; width: isActive(33) ? rTL * getXVal(33) : 0; height: isActive(33) ? rTL * getYo(33) : 0 }
    Region { x: isActive(34) ? inLeft - rTL * getXVal(34) + 1 : 0; y: isActive(34) ? inTop - rTL * getYo(34) : 0; width: isActive(34) ? rTL * getXVal(34) : 0; height: isActive(34) ? rTL * getYo(34) : 0 }
    Region { x: isActive(35) ? inLeft - rTL * getXVal(35) + 1 : 0; y: isActive(35) ? inTop - rTL * getYo(35) : 0; width: isActive(35) ? rTL * getXVal(35) : 0; height: isActive(35) ? rTL * getYo(35) : 0 }
    Region { x: isActive(36) ? inLeft - rTL * getXVal(36) + 1 : 0; y: isActive(36) ? inTop - rTL * getYo(36) : 0; width: isActive(36) ? rTL * getXVal(36) : 0; height: isActive(36) ? rTL * getYo(36) : 0 }
    Region { x: isActive(37) ? inLeft - rTL * getXVal(37) + 1 : 0; y: isActive(37) ? inTop - rTL * getYo(37) : 0; width: isActive(37) ? rTL * getXVal(37) : 0; height: isActive(37) ? rTL * getYo(37) : 0 }
    Region { x: isActive(38) ? inLeft - rTL * getXVal(38) + 1 : 0; y: isActive(38) ? inTop - rTL * getYo(38) : 0; width: isActive(38) ? rTL * getXVal(38) : 0; height: isActive(38) ? rTL * getYo(38) : 0 }
    Region { x: isActive(39) ? inLeft - rTL * getXVal(39) + 1 : 0; y: isActive(39) ? inTop - rTL * getYo(39) : 0; width: isActive(39) ? rTL * getXVal(39) : 0; height: isActive(39) ? rTL * getYo(39) : 0 }
    Region { x: isActive(40) ? inLeft - rTL * getXVal(40) + 1 : 0; y: isActive(40) ? inTop - rTL * getYo(40) : 0; width: isActive(40) ? rTL * getXVal(40) : 0; height: isActive(40) ? rTL * getYo(40) : 0 }
    Region { x: isActive(41) ? inLeft - rTL * getXVal(41) + 1 : 0; y: isActive(41) ? inTop - rTL * getYo(41) : 0; width: isActive(41) ? rTL * getXVal(41) : 0; height: isActive(41) ? rTL * getYo(41) : 0 }
    Region { x: isActive(42) ? inLeft - rTL * getXVal(42) + 1 : 0; y: isActive(42) ? inTop - rTL * getYo(42) : 0; width: isActive(42) ? rTL * getXVal(42) : 0; height: isActive(42) ? rTL * getYo(42) : 0 }
    Region { x: isActive(43) ? inLeft - rTL * getXVal(43) + 1 : 0; y: isActive(43) ? inTop - rTL * getYo(43) : 0; width: isActive(43) ? rTL * getXVal(43) : 0; height: isActive(43) ? rTL * getYo(43) : 0 }
    Region { x: isActive(44) ? inLeft - rTL * getXVal(44) + 1 : 0; y: isActive(44) ? inTop - rTL * getYo(44) : 0; width: isActive(44) ? rTL * getXVal(44) : 0; height: isActive(44) ? rTL * getYo(44) : 0 }
    Region { x: isActive(45) ? inLeft - rTL * getXVal(45) + 1 : 0; y: isActive(45) ? inTop - rTL * getYo(45) : 0; width: isActive(45) ? rTL * getXVal(45) : 0; height: isActive(45) ? rTL * getYo(45) : 0 }
    Region { x: isActive(46) ? inLeft - rTL * getXVal(46) + 1 : 0; y: isActive(46) ? inTop - rTL * getYo(46) : 0; width: isActive(46) ? rTL * getXVal(46) : 0; height: isActive(46) ? rTL * getYo(46) : 0 }
    Region { x: isActive(47) ? inLeft - rTL * getXVal(47) + 1 : 0; y: isActive(47) ? inTop - rTL * getYo(47) : 0; width: isActive(47) ? rTL * getXVal(47) : 0; height: isActive(47) ? rTL * getYo(47) : 0 }
    Region { x: isActive(48) ? inLeft - rTL * getXVal(48) + 1 : 0; y: isActive(48) ? inTop - rTL * getYo(48) : 0; width: isActive(48) ? rTL * getXVal(48) : 0; height: isActive(48) ? rTL * getYo(48) : 0 }
    Region { x: isActive(49) ? inLeft - rTL * getXVal(49) + 1 : 0; y: isActive(49) ? inTop - rTL * getYo(49) : 0; width: isActive(49) ? rTL * getXVal(49) : 0; height: isActive(49) ? rTL * getYo(49) : 0 }
    Region { x: isActive(50) ? inLeft - rTL * getXVal(50) + 1 : 0; y: isActive(50) ? inTop - rTL * getYo(50) : 0; width: isActive(50) ? rTL * getXVal(50) : 0; height: isActive(50) ? rTL * getYo(50) : 0 }
    Region { x: isActive(51) ? inLeft - rTL * getXVal(51) + 1 : 0; y: isActive(51) ? inTop - rTL * getYo(51) : 0; width: isActive(51) ? rTL * getXVal(51) : 0; height: isActive(51) ? rTL * getYo(51) : 0 }
    Region { x: isActive(52) ? inLeft - rTL * getXVal(52) + 1 : 0; y: isActive(52) ? inTop - rTL * getYo(52) : 0; width: isActive(52) ? rTL * getXVal(52) : 0; height: isActive(52) ? rTL * getYo(52) : 0 }
    Region { x: isActive(53) ? inLeft - rTL * getXVal(53) + 1 : 0; y: isActive(53) ? inTop - rTL * getYo(53) : 0; width: isActive(53) ? rTL * getXVal(53) : 0; height: isActive(53) ? rTL * getYo(53) : 0 }
    Region { x: isActive(54) ? inLeft - rTL * getXVal(54) + 1 : 0; y: isActive(54) ? inTop - rTL * getYo(54) : 0; width: isActive(54) ? rTL * getXVal(54) : 0; height: isActive(54) ? rTL * getYo(54) : 0 }
    Region { x: isActive(55) ? inLeft - rTL * getXVal(55) + 1 : 0; y: isActive(55) ? inTop - rTL * getYo(55) : 0; width: isActive(55) ? rTL * getXVal(55) : 0; height: isActive(55) ? rTL * getYo(55) : 0 }
    Region { x: isActive(56) ? inLeft - rTL * getXVal(56) + 1 : 0; y: isActive(56) ? inTop - rTL * getYo(56) : 0; width: isActive(56) ? rTL * getXVal(56) : 0; height: isActive(56) ? rTL * getYo(56) : 0 }
    Region { x: isActive(57) ? inLeft - rTL * getXVal(57) + 1 : 0; y: isActive(57) ? inTop - rTL * getYo(57) : 0; width: isActive(57) ? rTL * getXVal(57) : 0; height: isActive(57) ? rTL * getYo(57) : 0 }
    Region { x: isActive(58) ? inLeft - rTL * getXVal(58) + 1 : 0; y: isActive(58) ? inTop - rTL * getYo(58) : 0; width: isActive(58) ? rTL * getXVal(58) : 0; height: isActive(58) ? rTL * getYo(58) : 0 }
    Region { x: isActive(59) ? inLeft - rTL * getXVal(59) + 1 : 0; y: isActive(59) ? inTop - rTL * getYo(59) : 0; width: isActive(59) ? rTL * getXVal(59) : 0; height: isActive(59) ? rTL * getYo(59) : 0 }
    Region { x: isActive(60) ? inLeft - rTL * getXVal(60) + 1 : 0; y: isActive(60) ? inTop - rTL * getYo(60) : 0; width: isActive(60) ? rTL * getXVal(60) : 0; height: isActive(60) ? rTL * getYo(60) : 0 }
    Region { x: isActive(61) ? inLeft - rTL * getXVal(61) + 1 : 0; y: isActive(61) ? inTop - rTL * getYo(61) : 0; width: isActive(61) ? rTL * getXVal(61) : 0; height: isActive(61) ? rTL * getYo(61) : 0 }
    Region { x: isActive(62) ? inLeft - rTL * getXVal(62) + 1 : 0; y: isActive(62) ? inTop - rTL * getYo(62) : 0; width: isActive(62) ? rTL * getXVal(62) : 0; height: isActive(62) ? rTL * getYo(62) : 0 }
    Region { x: isActive(63) ? inLeft - rTL * getXVal(63) + 1 : 0; y: isActive(63) ? inTop - rTL * getYo(63) : 0; width: isActive(63) ? rTL * getXVal(63) : 0; height: isActive(63) ? rTL * getYo(63) : 0 }
    Region { x: isActive(64) ? inLeft - rTL * getXVal(64) + 1 : 0; y: isActive(64) ? inTop - rTL * getYo(64) : 0; width: isActive(64) ? rTL * getXVal(64) : 0; height: isActive(64) ? rTL * getYo(64) : 0 }
    Region { x: isActive(65) ? inLeft - rTL * getXVal(65) + 1 : 0; y: isActive(65) ? inTop - rTL * getYo(65) : 0; width: isActive(65) ? rTL * getXVal(65) : 0; height: isActive(65) ? rTL * getYo(65) : 0 }
    Region { x: isActive(66) ? inLeft - rTL * getXVal(66) + 1 : 0; y: isActive(66) ? inTop - rTL * getYo(66) : 0; width: isActive(66) ? rTL * getXVal(66) : 0; height: isActive(66) ? rTL * getYo(66) : 0 }
    Region { x: isActive(67) ? inLeft - rTL * getXVal(67) + 1 : 0; y: isActive(67) ? inTop - rTL * getYo(67) : 0; width: isActive(67) ? rTL * getXVal(67) : 0; height: isActive(67) ? rTL * getYo(67) : 0 }
    Region { x: isActive(68) ? inLeft - rTL * getXVal(68) + 1 : 0; y: isActive(68) ? inTop - rTL * getYo(68) : 0; width: isActive(68) ? rTL * getXVal(68) : 0; height: isActive(68) ? rTL * getYo(68) : 0 }
    Region { x: isActive(69) ? inLeft - rTL * getXVal(69) + 1 : 0; y: isActive(69) ? inTop - rTL * getYo(69) : 0; width: isActive(69) ? rTL * getXVal(69) : 0; height: isActive(69) ? rTL * getYo(69) : 0 }
    Region { x: isActive(70) ? inLeft - rTL * getXVal(70) + 1 : 0; y: isActive(70) ? inTop - rTL * getYo(70) : 0; width: isActive(70) ? rTL * getXVal(70) : 0; height: isActive(70) ? rTL * getYo(70) : 0 }
    Region { x: isActive(71) ? inLeft - rTL * getXVal(71) + 1 : 0; y: isActive(71) ? inTop - rTL * getYo(71) : 0; width: isActive(71) ? rTL * getXVal(71) : 0; height: isActive(71) ? rTL * getYo(71) : 0 }
    Region { x: isActive(72) ? inLeft - rTL * getXVal(72) + 1 : 0; y: isActive(72) ? inTop - rTL * getYo(72) : 0; width: isActive(72) ? rTL * getXVal(72) : 0; height: isActive(72) ? rTL * getYo(72) : 0 }
    Region { x: isActive(73) ? inLeft - rTL * getXVal(73) + 1 : 0; y: isActive(73) ? inTop - rTL * getYo(73) : 0; width: isActive(73) ? rTL * getXVal(73) : 0; height: isActive(73) ? rTL * getYo(73) : 0 }
    Region { x: isActive(74) ? inLeft - rTL * getXVal(74) + 1 : 0; y: isActive(74) ? inTop - rTL * getYo(74) : 0; width: isActive(74) ? rTL * getXVal(74) : 0; height: isActive(74) ? rTL * getYo(74) : 0 }
    Region { x: isActive(75) ? inLeft - rTL * getXVal(75) + 1 : 0; y: isActive(75) ? inTop - rTL * getYo(75) : 0; width: isActive(75) ? rTL * getXVal(75) : 0; height: isActive(75) ? rTL * getYo(75) : 0 }
    Region { x: isActive(76) ? inLeft - rTL * getXVal(76) + 1 : 0; y: isActive(76) ? inTop - rTL * getYo(76) : 0; width: isActive(76) ? rTL * getXVal(76) : 0; height: isActive(76) ? rTL * getYo(76) : 0 }
    Region { x: isActive(77) ? inLeft - rTL * getXVal(77) + 1 : 0; y: isActive(77) ? inTop - rTL * getYo(77) : 0; width: isActive(77) ? rTL * getXVal(77) : 0; height: isActive(77) ? rTL * getYo(77) : 0 }
    Region { x: isActive(78) ? inLeft - rTL * getXVal(78) + 1 : 0; y: isActive(78) ? inTop - rTL * getYo(78) : 0; width: isActive(78) ? rTL * getXVal(78) : 0; height: isActive(78) ? rTL * getYo(78) : 0 }
    Region { x: isActive(79) ? inLeft - rTL * getXVal(79) + 1 : 0; y: isActive(79) ? inTop - rTL * getYo(79) : 0; width: isActive(79) ? rTL * getXVal(79) : 0; height: isActive(79) ? rTL * getYo(79) : 0 }
    Region { x: isActive(80) ? inLeft - rTL * getXVal(80) + 1 : 0; y: isActive(80) ? inTop - rTL * getYo(80) : 0; width: isActive(80) ? rTL * getXVal(80) : 0; height: isActive(80) ? rTL * getYo(80) : 0 }
    Region { x: isActive(81) ? inLeft - rTL * getXVal(81) + 1 : 0; y: isActive(81) ? inTop - rTL * getYo(81) : 0; width: isActive(81) ? rTL * getXVal(81) : 0; height: isActive(81) ? rTL * getYo(81) : 0 }
    Region { x: isActive(82) ? inLeft - rTL * getXVal(82) + 1 : 0; y: isActive(82) ? inTop - rTL * getYo(82) : 0; width: isActive(82) ? rTL * getXVal(82) : 0; height: isActive(82) ? rTL * getYo(82) : 0 }
    Region { x: isActive(83) ? inLeft - rTL * getXVal(83) + 1 : 0; y: isActive(83) ? inTop - rTL * getYo(83) : 0; width: isActive(83) ? rTL * getXVal(83) : 0; height: isActive(83) ? rTL * getYo(83) : 0 }
    Region { x: isActive(84) ? inLeft - rTL * getXVal(84) + 1 : 0; y: isActive(84) ? inTop - rTL * getYo(84) : 0; width: isActive(84) ? rTL * getXVal(84) : 0; height: isActive(84) ? rTL * getYo(84) : 0 }
    Region { x: isActive(85) ? inLeft - rTL * getXVal(85) + 1 : 0; y: isActive(85) ? inTop - rTL * getYo(85) : 0; width: isActive(85) ? rTL * getXVal(85) : 0; height: isActive(85) ? rTL * getYo(85) : 0 }
    Region { x: isActive(86) ? inLeft - rTL * getXVal(86) + 1 : 0; y: isActive(86) ? inTop - rTL * getYo(86) : 0; width: isActive(86) ? rTL * getXVal(86) : 0; height: isActive(86) ? rTL * getYo(86) : 0 }
    Region { x: isActive(87) ? inLeft - rTL * getXVal(87) + 1 : 0; y: isActive(87) ? inTop - rTL * getYo(87) : 0; width: isActive(87) ? rTL * getXVal(87) : 0; height: isActive(87) ? rTL * getYo(87) : 0 }
    Region { x: isActive(88) ? inLeft - rTL * getXVal(88) + 1 : 0; y: isActive(88) ? inTop - rTL * getYo(88) : 0; width: isActive(88) ? rTL * getXVal(88) : 0; height: isActive(88) ? rTL * getYo(88) : 0 }
    Region { x: isActive(89) ? inLeft - rTL * getXVal(89) + 1 : 0; y: isActive(89) ? inTop - rTL * getYo(89) : 0; width: isActive(89) ? rTL * getXVal(89) : 0; height: isActive(89) ? rTL * getYo(89) : 0 }
    Region { x: isActive(90) ? inLeft - rTL * getXVal(90) + 1 : 0; y: isActive(90) ? inTop - rTL * getYo(90) : 0; width: isActive(90) ? rTL * getXVal(90) : 0; height: isActive(90) ? rTL * getYo(90) : 0 }
    Region { x: isActive(91) ? inLeft - rTL * getXVal(91) + 1 : 0; y: isActive(91) ? inTop - rTL * getYo(91) : 0; width: isActive(91) ? rTL * getXVal(91) : 0; height: isActive(91) ? rTL * getYo(91) : 0 }
    Region { x: isActive(92) ? inLeft - rTL * getXVal(92) + 1 : 0; y: isActive(92) ? inTop - rTL * getYo(92) : 0; width: isActive(92) ? rTL * getXVal(92) : 0; height: isActive(92) ? rTL * getYo(92) : 0 }
    Region { x: isActive(93) ? inLeft - rTL * getXVal(93) + 1 : 0; y: isActive(93) ? inTop - rTL * getYo(93) : 0; width: isActive(93) ? rTL * getXVal(93) : 0; height: isActive(93) ? rTL * getYo(93) : 0 }
    Region { x: isActive(94) ? inLeft - rTL * getXVal(94) + 1 : 0; y: isActive(94) ? inTop - rTL * getYo(94) : 0; width: isActive(94) ? rTL * getXVal(94) : 0; height: isActive(94) ? rTL * getYo(94) : 0 }
    Region { x: isActive(95) ? inLeft - rTL * getXVal(95) + 1 : 0; y: isActive(95) ? inTop - rTL * getYo(95) : 0; width: isActive(95) ? rTL * getXVal(95) : 0; height: isActive(95) ? rTL * getYo(95) : 0 }
    Region { x: isActive(96) ? inLeft - rTL * getXVal(96) + 1 : 0; y: isActive(96) ? inTop - rTL * getYo(96) : 0; width: isActive(96) ? rTL * getXVal(96) : 0; height: isActive(96) ? rTL * getYo(96) : 0 }
    Region { x: isActive(97) ? inLeft - rTL * getXVal(97) + 1 : 0; y: isActive(97) ? inTop - rTL * getYo(97) : 0; width: isActive(97) ? rTL * getXVal(97) : 0; height: isActive(97) ? rTL * getYo(97) : 0 }
    Region { x: isActive(98) ? inLeft - rTL * getXVal(98) + 1 : 0; y: isActive(98) ? inTop - rTL * getYo(98) : 0; width: isActive(98) ? rTL * getXVal(98) : 0; height: isActive(98) ? rTL * getYo(98) : 0 }
    Region { x: isActive(99) ? inLeft - rTL * getXVal(99) + 1 : 0; y: isActive(99) ? inTop - rTL * getYo(99) : 0; width: isActive(99) ? rTL * getXVal(99) : 0; height: isActive(99) ? rTL * getYo(99) : 0 }
    Region { x: isActive(100) ? inLeft - rTL * getXVal(100) + 1 : 0; y: isActive(100) ? inTop - rTL * getYo(100) : 0; width: isActive(100) ? rTL * getXVal(100) : 0; height: isActive(100) ? rTL * getYo(100) : 0 }

    // Top-Right Outer Corner
    Region { x: isActive(1) ? inRight : 0; y: isActive(1) ? inTop - rTR * getYo(1) : 0; width: isActive(1) ? rTR * getXVal(1) : 0; height: isActive(1) ? rTR * getYo(1) : 0 }
    Region { x: isActive(2) ? inRight : 0; y: isActive(2) ? inTop - rTR * getYo(2) : 0; width: isActive(2) ? rTR * getXVal(2) : 0; height: isActive(2) ? rTR * getYo(2) : 0 }
    Region { x: isActive(3) ? inRight : 0; y: isActive(3) ? inTop - rTR * getYo(3) : 0; width: isActive(3) ? rTR * getXVal(3) : 0; height: isActive(3) ? rTR * getYo(3) : 0 }
    Region { x: isActive(4) ? inRight : 0; y: isActive(4) ? inTop - rTR * getYo(4) : 0; width: isActive(4) ? rTR * getXVal(4) : 0; height: isActive(4) ? rTR * getYo(4) : 0 }
    Region { x: isActive(5) ? inRight : 0; y: isActive(5) ? inTop - rTR * getYo(5) : 0; width: isActive(5) ? rTR * getXVal(5) : 0; height: isActive(5) ? rTR * getYo(5) : 0 }
    Region { x: isActive(6) ? inRight : 0; y: isActive(6) ? inTop - rTR * getYo(6) : 0; width: isActive(6) ? rTR * getXVal(6) : 0; height: isActive(6) ? rTR * getYo(6) : 0 }
    Region { x: isActive(7) ? inRight : 0; y: isActive(7) ? inTop - rTR * getYo(7) : 0; width: isActive(7) ? rTR * getXVal(7) : 0; height: isActive(7) ? rTR * getYo(7) : 0 }
    Region { x: isActive(8) ? inRight : 0; y: isActive(8) ? inTop - rTR * getYo(8) : 0; width: isActive(8) ? rTR * getXVal(8) : 0; height: isActive(8) ? rTR * getYo(8) : 0 }
    Region { x: isActive(9) ? inRight : 0; y: isActive(9) ? inTop - rTR * getYo(9) : 0; width: isActive(9) ? rTR * getXVal(9) : 0; height: isActive(9) ? rTR * getYo(9) : 0 }
    Region { x: isActive(10) ? inRight : 0; y: isActive(10) ? inTop - rTR * getYo(10) : 0; width: isActive(10) ? rTR * getXVal(10) : 0; height: isActive(10) ? rTR * getYo(10) : 0 }
    Region { x: isActive(11) ? inRight : 0; y: isActive(11) ? inTop - rTR * getYo(11) : 0; width: isActive(11) ? rTR * getXVal(11) : 0; height: isActive(11) ? rTR * getYo(11) : 0 }
    Region { x: isActive(12) ? inRight : 0; y: isActive(12) ? inTop - rTR * getYo(12) : 0; width: isActive(12) ? rTR * getXVal(12) : 0; height: isActive(12) ? rTR * getYo(12) : 0 }
    Region { x: isActive(13) ? inRight : 0; y: isActive(13) ? inTop - rTR * getYo(13) : 0; width: isActive(13) ? rTR * getXVal(13) : 0; height: isActive(13) ? rTR * getYo(13) : 0 }
    Region { x: isActive(14) ? inRight : 0; y: isActive(14) ? inTop - rTR * getYo(14) : 0; width: isActive(14) ? rTR * getXVal(14) : 0; height: isActive(14) ? rTR * getYo(14) : 0 }
    Region { x: isActive(15) ? inRight : 0; y: isActive(15) ? inTop - rTR * getYo(15) : 0; width: isActive(15) ? rTR * getXVal(15) : 0; height: isActive(15) ? rTR * getYo(15) : 0 }
    Region { x: isActive(16) ? inRight : 0; y: isActive(16) ? inTop - rTR * getYo(16) : 0; width: isActive(16) ? rTR * getXVal(16) : 0; height: isActive(16) ? rTR * getYo(16) : 0 }
    Region { x: isActive(17) ? inRight : 0; y: isActive(17) ? inTop - rTR * getYo(17) : 0; width: isActive(17) ? rTR * getXVal(17) : 0; height: isActive(17) ? rTR * getYo(17) : 0 }
    Region { x: isActive(18) ? inRight : 0; y: isActive(18) ? inTop - rTR * getYo(18) : 0; width: isActive(18) ? rTR * getXVal(18) : 0; height: isActive(18) ? rTR * getYo(18) : 0 }
    Region { x: isActive(19) ? inRight : 0; y: isActive(19) ? inTop - rTR * getYo(19) : 0; width: isActive(19) ? rTR * getXVal(19) : 0; height: isActive(19) ? rTR * getYo(19) : 0 }
    Region { x: isActive(20) ? inRight : 0; y: isActive(20) ? inTop - rTR * getYo(20) : 0; width: isActive(20) ? rTR * getXVal(20) : 0; height: isActive(20) ? rTR * getYo(20) : 0 }
    Region { x: isActive(21) ? inRight : 0; y: isActive(21) ? inTop - rTR * getYo(21) : 0; width: isActive(21) ? rTR * getXVal(21) : 0; height: isActive(21) ? rTR * getYo(21) : 0 }
    Region { x: isActive(22) ? inRight : 0; y: isActive(22) ? inTop - rTR * getYo(22) : 0; width: isActive(22) ? rTR * getXVal(22) : 0; height: isActive(22) ? rTR * getYo(22) : 0 }
    Region { x: isActive(23) ? inRight : 0; y: isActive(23) ? inTop - rTR * getYo(23) : 0; width: isActive(23) ? rTR * getXVal(23) : 0; height: isActive(23) ? rTR * getYo(23) : 0 }
    Region { x: isActive(24) ? inRight : 0; y: isActive(24) ? inTop - rTR * getYo(24) : 0; width: isActive(24) ? rTR * getXVal(24) : 0; height: isActive(24) ? rTR * getYo(24) : 0 }
    Region { x: isActive(25) ? inRight : 0; y: isActive(25) ? inTop - rTR * getYo(25) : 0; width: isActive(25) ? rTR * getXVal(25) : 0; height: isActive(25) ? rTR * getYo(25) : 0 }
    Region { x: isActive(26) ? inRight : 0; y: isActive(26) ? inTop - rTR * getYo(26) : 0; width: isActive(26) ? rTR * getXVal(26) : 0; height: isActive(26) ? rTR * getYo(26) : 0 }
    Region { x: isActive(27) ? inRight : 0; y: isActive(27) ? inTop - rTR * getYo(27) : 0; width: isActive(27) ? rTR * getXVal(27) : 0; height: isActive(27) ? rTR * getYo(27) : 0 }
    Region { x: isActive(28) ? inRight : 0; y: isActive(28) ? inTop - rTR * getYo(28) : 0; width: isActive(28) ? rTR * getXVal(28) : 0; height: isActive(28) ? rTR * getYo(28) : 0 }
    Region { x: isActive(29) ? inRight : 0; y: isActive(29) ? inTop - rTR * getYo(29) : 0; width: isActive(29) ? rTR * getXVal(29) : 0; height: isActive(29) ? rTR * getYo(29) : 0 }
    Region { x: isActive(30) ? inRight : 0; y: isActive(30) ? inTop - rTR * getYo(30) : 0; width: isActive(30) ? rTR * getXVal(30) : 0; height: isActive(30) ? rTR * getYo(30) : 0 }
    Region { x: isActive(31) ? inRight : 0; y: isActive(31) ? inTop - rTR * getYo(31) : 0; width: isActive(31) ? rTR * getXVal(31) : 0; height: isActive(31) ? rTR * getYo(31) : 0 }
    Region { x: isActive(32) ? inRight : 0; y: isActive(32) ? inTop - rTR * getYo(32) : 0; width: isActive(32) ? rTR * getXVal(32) : 0; height: isActive(32) ? rTR * getYo(32) : 0 }
    Region { x: isActive(33) ? inRight : 0; y: isActive(33) ? inTop - rTR * getYo(33) : 0; width: isActive(33) ? rTR * getXVal(33) : 0; height: isActive(33) ? rTR * getYo(33) : 0 }
    Region { x: isActive(34) ? inRight : 0; y: isActive(34) ? inTop - rTR * getYo(34) : 0; width: isActive(34) ? rTR * getXVal(34) : 0; height: isActive(34) ? rTR * getYo(34) : 0 }
    Region { x: isActive(35) ? inRight : 0; y: isActive(35) ? inTop - rTR * getYo(35) : 0; width: isActive(35) ? rTR * getXVal(35) : 0; height: isActive(35) ? rTR * getYo(35) : 0 }
    Region { x: isActive(36) ? inRight : 0; y: isActive(36) ? inTop - rTR * getYo(36) : 0; width: isActive(36) ? rTR * getXVal(36) : 0; height: isActive(36) ? rTR * getYo(36) : 0 }
    Region { x: isActive(37) ? inRight : 0; y: isActive(37) ? inTop - rTR * getYo(37) : 0; width: isActive(37) ? rTR * getXVal(37) : 0; height: isActive(37) ? rTR * getYo(37) : 0 }
    Region { x: isActive(38) ? inRight : 0; y: isActive(38) ? inTop - rTR * getYo(38) : 0; width: isActive(38) ? rTR * getXVal(38) : 0; height: isActive(38) ? rTR * getYo(38) : 0 }
    Region { x: isActive(39) ? inRight : 0; y: isActive(39) ? inTop - rTR * getYo(39) : 0; width: isActive(39) ? rTR * getXVal(39) : 0; height: isActive(39) ? rTR * getYo(39) : 0 }
    Region { x: isActive(40) ? inRight : 0; y: isActive(40) ? inTop - rTR * getYo(40) : 0; width: isActive(40) ? rTR * getXVal(40) : 0; height: isActive(40) ? rTR * getYo(40) : 0 }
    Region { x: isActive(41) ? inRight : 0; y: isActive(41) ? inTop - rTR * getYo(41) : 0; width: isActive(41) ? rTR * getXVal(41) : 0; height: isActive(41) ? rTR * getYo(41) : 0 }
    Region { x: isActive(42) ? inRight : 0; y: isActive(42) ? inTop - rTR * getYo(42) : 0; width: isActive(42) ? rTR * getXVal(42) : 0; height: isActive(42) ? rTR * getYo(42) : 0 }
    Region { x: isActive(43) ? inRight : 0; y: isActive(43) ? inTop - rTR * getYo(43) : 0; width: isActive(43) ? rTR * getXVal(43) : 0; height: isActive(43) ? rTR * getYo(43) : 0 }
    Region { x: isActive(44) ? inRight : 0; y: isActive(44) ? inTop - rTR * getYo(44) : 0; width: isActive(44) ? rTR * getXVal(44) : 0; height: isActive(44) ? rTR * getYo(44) : 0 }
    Region { x: isActive(45) ? inRight : 0; y: isActive(45) ? inTop - rTR * getYo(45) : 0; width: isActive(45) ? rTR * getXVal(45) : 0; height: isActive(45) ? rTR * getYo(45) : 0 }
    Region { x: isActive(46) ? inRight : 0; y: isActive(46) ? inTop - rTR * getYo(46) : 0; width: isActive(46) ? rTR * getXVal(46) : 0; height: isActive(46) ? rTR * getYo(46) : 0 }
    Region { x: isActive(47) ? inRight : 0; y: isActive(47) ? inTop - rTR * getYo(47) : 0; width: isActive(47) ? rTR * getXVal(47) : 0; height: isActive(47) ? rTR * getYo(47) : 0 }
    Region { x: isActive(48) ? inRight : 0; y: isActive(48) ? inTop - rTR * getYo(48) : 0; width: isActive(48) ? rTR * getXVal(48) : 0; height: isActive(48) ? rTR * getYo(48) : 0 }
    Region { x: isActive(49) ? inRight : 0; y: isActive(49) ? inTop - rTR * getYo(49) : 0; width: isActive(49) ? rTR * getXVal(49) : 0; height: isActive(49) ? rTR * getYo(49) : 0 }
    Region { x: isActive(50) ? inRight : 0; y: isActive(50) ? inTop - rTR * getYo(50) : 0; width: isActive(50) ? rTR * getXVal(50) : 0; height: isActive(50) ? rTR * getYo(50) : 0 }
    Region { x: isActive(51) ? inRight : 0; y: isActive(51) ? inTop - rTR * getYo(51) : 0; width: isActive(51) ? rTR * getXVal(51) : 0; height: isActive(51) ? rTR * getYo(51) : 0 }
    Region { x: isActive(52) ? inRight : 0; y: isActive(52) ? inTop - rTR * getYo(52) : 0; width: isActive(52) ? rTR * getXVal(52) : 0; height: isActive(52) ? rTR * getYo(52) : 0 }
    Region { x: isActive(53) ? inRight : 0; y: isActive(53) ? inTop - rTR * getYo(53) : 0; width: isActive(53) ? rTR * getXVal(53) : 0; height: isActive(53) ? rTR * getYo(53) : 0 }
    Region { x: isActive(54) ? inRight : 0; y: isActive(54) ? inTop - rTR * getYo(54) : 0; width: isActive(54) ? rTR * getXVal(54) : 0; height: isActive(54) ? rTR * getYo(54) : 0 }
    Region { x: isActive(55) ? inRight : 0; y: isActive(55) ? inTop - rTR * getYo(55) : 0; width: isActive(55) ? rTR * getXVal(55) : 0; height: isActive(55) ? rTR * getYo(55) : 0 }
    Region { x: isActive(56) ? inRight : 0; y: isActive(56) ? inTop - rTR * getYo(56) : 0; width: isActive(56) ? rTR * getXVal(56) : 0; height: isActive(56) ? rTR * getYo(56) : 0 }
    Region { x: isActive(57) ? inRight : 0; y: isActive(57) ? inTop - rTR * getYo(57) : 0; width: isActive(57) ? rTR * getXVal(57) : 0; height: isActive(57) ? rTR * getYo(57) : 0 }
    Region { x: isActive(58) ? inRight : 0; y: isActive(58) ? inTop - rTR * getYo(58) : 0; width: isActive(58) ? rTR * getXVal(58) : 0; height: isActive(58) ? rTR * getYo(58) : 0 }
    Region { x: isActive(59) ? inRight : 0; y: isActive(59) ? inTop - rTR * getYo(59) : 0; width: isActive(59) ? rTR * getXVal(59) : 0; height: isActive(59) ? rTR * getYo(59) : 0 }
    Region { x: isActive(60) ? inRight : 0; y: isActive(60) ? inTop - rTR * getYo(60) : 0; width: isActive(60) ? rTR * getXVal(60) : 0; height: isActive(60) ? rTR * getYo(60) : 0 }
    Region { x: isActive(61) ? inRight : 0; y: isActive(61) ? inTop - rTR * getYo(61) : 0; width: isActive(61) ? rTR * getXVal(61) : 0; height: isActive(61) ? rTR * getYo(61) : 0 }
    Region { x: isActive(62) ? inRight : 0; y: isActive(62) ? inTop - rTR * getYo(62) : 0; width: isActive(62) ? rTR * getXVal(62) : 0; height: isActive(62) ? rTR * getYo(62) : 0 }
    Region { x: isActive(63) ? inRight : 0; y: isActive(63) ? inTop - rTR * getYo(63) : 0; width: isActive(63) ? rTR * getXVal(63) : 0; height: isActive(63) ? rTR * getYo(63) : 0 }
    Region { x: isActive(64) ? inRight : 0; y: isActive(64) ? inTop - rTR * getYo(64) : 0; width: isActive(64) ? rTR * getXVal(64) : 0; height: isActive(64) ? rTR * getYo(64) : 0 }
    Region { x: isActive(65) ? inRight : 0; y: isActive(65) ? inTop - rTR * getYo(65) : 0; width: isActive(65) ? rTR * getXVal(65) : 0; height: isActive(65) ? rTR * getYo(65) : 0 }
    Region { x: isActive(66) ? inRight : 0; y: isActive(66) ? inTop - rTR * getYo(66) : 0; width: isActive(66) ? rTR * getXVal(66) : 0; height: isActive(66) ? rTR * getYo(66) : 0 }
    Region { x: isActive(67) ? inRight : 0; y: isActive(67) ? inTop - rTR * getYo(67) : 0; width: isActive(67) ? rTR * getXVal(67) : 0; height: isActive(67) ? rTR * getYo(67) : 0 }
    Region { x: isActive(68) ? inRight : 0; y: isActive(68) ? inTop - rTR * getYo(68) : 0; width: isActive(68) ? rTR * getXVal(68) : 0; height: isActive(68) ? rTR * getYo(68) : 0 }
    Region { x: isActive(69) ? inRight : 0; y: isActive(69) ? inTop - rTR * getYo(69) : 0; width: isActive(69) ? rTR * getXVal(69) : 0; height: isActive(69) ? rTR * getYo(69) : 0 }
    Region { x: isActive(70) ? inRight : 0; y: isActive(70) ? inTop - rTR * getYo(70) : 0; width: isActive(70) ? rTR * getXVal(70) : 0; height: isActive(70) ? rTR * getYo(70) : 0 }
    Region { x: isActive(71) ? inRight : 0; y: isActive(71) ? inTop - rTR * getYo(71) : 0; width: isActive(71) ? rTR * getXVal(71) : 0; height: isActive(71) ? rTR * getYo(71) : 0 }
    Region { x: isActive(72) ? inRight : 0; y: isActive(72) ? inTop - rTR * getYo(72) : 0; width: isActive(72) ? rTR * getXVal(72) : 0; height: isActive(72) ? rTR * getYo(72) : 0 }
    Region { x: isActive(73) ? inRight : 0; y: isActive(73) ? inTop - rTR * getYo(73) : 0; width: isActive(73) ? rTR * getXVal(73) : 0; height: isActive(73) ? rTR * getYo(73) : 0 }
    Region { x: isActive(74) ? inRight : 0; y: isActive(74) ? inTop - rTR * getYo(74) : 0; width: isActive(74) ? rTR * getXVal(74) : 0; height: isActive(74) ? rTR * getYo(74) : 0 }
    Region { x: isActive(75) ? inRight : 0; y: isActive(75) ? inTop - rTR * getYo(75) : 0; width: isActive(75) ? rTR * getXVal(75) : 0; height: isActive(75) ? rTR * getYo(75) : 0 }
    Region { x: isActive(76) ? inRight : 0; y: isActive(76) ? inTop - rTR * getYo(76) : 0; width: isActive(76) ? rTR * getXVal(76) : 0; height: isActive(76) ? rTR * getYo(76) : 0 }
    Region { x: isActive(77) ? inRight : 0; y: isActive(77) ? inTop - rTR * getYo(77) : 0; width: isActive(77) ? rTR * getXVal(77) : 0; height: isActive(77) ? rTR * getYo(77) : 0 }
    Region { x: isActive(78) ? inRight : 0; y: isActive(78) ? inTop - rTR * getYo(78) : 0; width: isActive(78) ? rTR * getXVal(78) : 0; height: isActive(78) ? rTR * getYo(78) : 0 }
    Region { x: isActive(79) ? inRight : 0; y: isActive(79) ? inTop - rTR * getYo(79) : 0; width: isActive(79) ? rTR * getXVal(79) : 0; height: isActive(79) ? rTR * getYo(79) : 0 }
    Region { x: isActive(80) ? inRight : 0; y: isActive(80) ? inTop - rTR * getYo(80) : 0; width: isActive(80) ? rTR * getXVal(80) : 0; height: isActive(80) ? rTR * getYo(80) : 0 }
    Region { x: isActive(81) ? inRight : 0; y: isActive(81) ? inTop - rTR * getYo(81) : 0; width: isActive(81) ? rTR * getXVal(81) : 0; height: isActive(81) ? rTR * getYo(81) : 0 }
    Region { x: isActive(82) ? inRight : 0; y: isActive(82) ? inTop - rTR * getYo(82) : 0; width: isActive(82) ? rTR * getXVal(82) : 0; height: isActive(82) ? rTR * getYo(82) : 0 }
    Region { x: isActive(83) ? inRight : 0; y: isActive(83) ? inTop - rTR * getYo(83) : 0; width: isActive(83) ? rTR * getXVal(83) : 0; height: isActive(83) ? rTR * getYo(83) : 0 }
    Region { x: isActive(84) ? inRight : 0; y: isActive(84) ? inTop - rTR * getYo(84) : 0; width: isActive(84) ? rTR * getXVal(84) : 0; height: isActive(84) ? rTR * getYo(84) : 0 }
    Region { x: isActive(85) ? inRight : 0; y: isActive(85) ? inTop - rTR * getYo(85) : 0; width: isActive(85) ? rTR * getXVal(85) : 0; height: isActive(85) ? rTR * getYo(85) : 0 }
    Region { x: isActive(86) ? inRight : 0; y: isActive(86) ? inTop - rTR * getYo(86) : 0; width: isActive(86) ? rTR * getXVal(86) : 0; height: isActive(86) ? rTR * getYo(86) : 0 }
    Region { x: isActive(87) ? inRight : 0; y: isActive(87) ? inTop - rTR * getYo(87) : 0; width: isActive(87) ? rTR * getXVal(87) : 0; height: isActive(87) ? rTR * getYo(87) : 0 }
    Region { x: isActive(88) ? inRight : 0; y: isActive(88) ? inTop - rTR * getYo(88) : 0; width: isActive(88) ? rTR * getXVal(88) : 0; height: isActive(88) ? rTR * getYo(88) : 0 }
    Region { x: isActive(89) ? inRight : 0; y: isActive(89) ? inTop - rTR * getYo(89) : 0; width: isActive(89) ? rTR * getXVal(89) : 0; height: isActive(89) ? rTR * getYo(89) : 0 }
    Region { x: isActive(90) ? inRight : 0; y: isActive(90) ? inTop - rTR * getYo(90) : 0; width: isActive(90) ? rTR * getXVal(90) : 0; height: isActive(90) ? rTR * getYo(90) : 0 }
    Region { x: isActive(91) ? inRight : 0; y: isActive(91) ? inTop - rTR * getYo(91) : 0; width: isActive(91) ? rTR * getXVal(91) : 0; height: isActive(91) ? rTR * getYo(91) : 0 }
    Region { x: isActive(92) ? inRight : 0; y: isActive(92) ? inTop - rTR * getYo(92) : 0; width: isActive(92) ? rTR * getXVal(92) : 0; height: isActive(92) ? rTR * getYo(92) : 0 }
    Region { x: isActive(93) ? inRight : 0; y: isActive(93) ? inTop - rTR * getYo(93) : 0; width: isActive(93) ? rTR * getXVal(93) : 0; height: isActive(93) ? rTR * getYo(93) : 0 }
    Region { x: isActive(94) ? inRight : 0; y: isActive(94) ? inTop - rTR * getYo(94) : 0; width: isActive(94) ? rTR * getXVal(94) : 0; height: isActive(94) ? rTR * getYo(94) : 0 }
    Region { x: isActive(95) ? inRight : 0; y: isActive(95) ? inTop - rTR * getYo(95) : 0; width: isActive(95) ? rTR * getXVal(95) : 0; height: isActive(95) ? rTR * getYo(95) : 0 }
    Region { x: isActive(96) ? inRight : 0; y: isActive(96) ? inTop - rTR * getYo(96) : 0; width: isActive(96) ? rTR * getXVal(96) : 0; height: isActive(96) ? rTR * getYo(96) : 0 }
    Region { x: isActive(97) ? inRight : 0; y: isActive(97) ? inTop - rTR * getYo(97) : 0; width: isActive(97) ? rTR * getXVal(97) : 0; height: isActive(97) ? rTR * getYo(97) : 0 }
    Region { x: isActive(98) ? inRight : 0; y: isActive(98) ? inTop - rTR * getYo(98) : 0; width: isActive(98) ? rTR * getXVal(98) : 0; height: isActive(98) ? rTR * getYo(98) : 0 }
    Region { x: isActive(99) ? inRight : 0; y: isActive(99) ? inTop - rTR * getYo(99) : 0; width: isActive(99) ? rTR * getXVal(99) : 0; height: isActive(99) ? rTR * getYo(99) : 0 }
    Region { x: isActive(100) ? inRight : 0; y: isActive(100) ? inTop - rTR * getYo(100) : 0; width: isActive(100) ? rTR * getXVal(100) : 0; height: isActive(100) ? rTR * getYo(100) : 0 }

    // Bottom-Left Outer Corner
    Region { x: isActive(1) ? inLeft - rBL * getXVal(1) + 1 : 0; y: isActive(1) ? inBottom : 0; width: isActive(1) ? rBL * getXVal(1) : 0; height: isActive(1) ? rBL * getYo(1) : 0 }
    Region { x: isActive(2) ? inLeft - rBL * getXVal(2) + 1 : 0; y: isActive(2) ? inBottom : 0; width: isActive(2) ? rBL * getXVal(2) : 0; height: isActive(2) ? rBL * getYo(2) : 0 }
    Region { x: isActive(3) ? inLeft - rBL * getXVal(3) + 1 : 0; y: isActive(3) ? inBottom : 0; width: isActive(3) ? rBL * getXVal(3) : 0; height: isActive(3) ? rBL * getYo(3) : 0 }
    Region { x: isActive(4) ? inLeft - rBL * getXVal(4) + 1 : 0; y: isActive(4) ? inBottom : 0; width: isActive(4) ? rBL * getXVal(4) : 0; height: isActive(4) ? rBL * getYo(4) : 0 }
    Region { x: isActive(5) ? inLeft - rBL * getXVal(5) + 1 : 0; y: isActive(5) ? inBottom : 0; width: isActive(5) ? rBL * getXVal(5) : 0; height: isActive(5) ? rBL * getYo(5) : 0 }
    Region { x: isActive(6) ? inLeft - rBL * getXVal(6) + 1 : 0; y: isActive(6) ? inBottom : 0; width: isActive(6) ? rBL * getXVal(6) : 0; height: isActive(6) ? rBL * getYo(6) : 0 }
    Region { x: isActive(7) ? inLeft - rBL * getXVal(7) + 1 : 0; y: isActive(7) ? inBottom : 0; width: isActive(7) ? rBL * getXVal(7) : 0; height: isActive(7) ? rBL * getYo(7) : 0 }
    Region { x: isActive(8) ? inLeft - rBL * getXVal(8) + 1 : 0; y: isActive(8) ? inBottom : 0; width: isActive(8) ? rBL * getXVal(8) : 0; height: isActive(8) ? rBL * getYo(8) : 0 }
    Region { x: isActive(9) ? inLeft - rBL * getXVal(9) + 1 : 0; y: isActive(9) ? inBottom : 0; width: isActive(9) ? rBL * getXVal(9) : 0; height: isActive(9) ? rBL * getYo(9) : 0 }
    Region { x: isActive(10) ? inLeft - rBL * getXVal(10) + 1 : 0; y: isActive(10) ? inBottom : 0; width: isActive(10) ? rBL * getXVal(10) : 0; height: isActive(10) ? rBL * getYo(10) : 0 }
    Region { x: isActive(11) ? inLeft - rBL * getXVal(11) + 1 : 0; y: isActive(11) ? inBottom : 0; width: isActive(11) ? rBL * getXVal(11) : 0; height: isActive(11) ? rBL * getYo(11) : 0 }
    Region { x: isActive(12) ? inLeft - rBL * getXVal(12) + 1 : 0; y: isActive(12) ? inBottom : 0; width: isActive(12) ? rBL * getXVal(12) : 0; height: isActive(12) ? rBL * getYo(12) : 0 }
    Region { x: isActive(13) ? inLeft - rBL * getXVal(13) + 1 : 0; y: isActive(13) ? inBottom : 0; width: isActive(13) ? rBL * getXVal(13) : 0; height: isActive(13) ? rBL * getYo(13) : 0 }
    Region { x: isActive(14) ? inLeft - rBL * getXVal(14) + 1 : 0; y: isActive(14) ? inBottom : 0; width: isActive(14) ? rBL * getXVal(14) : 0; height: isActive(14) ? rBL * getYo(14) : 0 }
    Region { x: isActive(15) ? inLeft - rBL * getXVal(15) + 1 : 0; y: isActive(15) ? inBottom : 0; width: isActive(15) ? rBL * getXVal(15) : 0; height: isActive(15) ? rBL * getYo(15) : 0 }
    Region { x: isActive(16) ? inLeft - rBL * getXVal(16) + 1 : 0; y: isActive(16) ? inBottom : 0; width: isActive(16) ? rBL * getXVal(16) : 0; height: isActive(16) ? rBL * getYo(16) : 0 }
    Region { x: isActive(17) ? inLeft - rBL * getXVal(17) + 1 : 0; y: isActive(17) ? inBottom : 0; width: isActive(17) ? rBL * getXVal(17) : 0; height: isActive(17) ? rBL * getYo(17) : 0 }
    Region { x: isActive(18) ? inLeft - rBL * getXVal(18) + 1 : 0; y: isActive(18) ? inBottom : 0; width: isActive(18) ? rBL * getXVal(18) : 0; height: isActive(18) ? rBL * getYo(18) : 0 }
    Region { x: isActive(19) ? inLeft - rBL * getXVal(19) + 1 : 0; y: isActive(19) ? inBottom : 0; width: isActive(19) ? rBL * getXVal(19) : 0; height: isActive(19) ? rBL * getYo(19) : 0 }
    Region { x: isActive(20) ? inLeft - rBL * getXVal(20) + 1 : 0; y: isActive(20) ? inBottom : 0; width: isActive(20) ? rBL * getXVal(20) : 0; height: isActive(20) ? rBL * getYo(20) : 0 }
    Region { x: isActive(21) ? inLeft - rBL * getXVal(21) + 1 : 0; y: isActive(21) ? inBottom : 0; width: isActive(21) ? rBL * getXVal(21) : 0; height: isActive(21) ? rBL * getYo(21) : 0 }
    Region { x: isActive(22) ? inLeft - rBL * getXVal(22) + 1 : 0; y: isActive(22) ? inBottom : 0; width: isActive(22) ? rBL * getXVal(22) : 0; height: isActive(22) ? rBL * getYo(22) : 0 }
    Region { x: isActive(23) ? inLeft - rBL * getXVal(23) + 1 : 0; y: isActive(23) ? inBottom : 0; width: isActive(23) ? rBL * getXVal(23) : 0; height: isActive(23) ? rBL * getYo(23) : 0 }
    Region { x: isActive(24) ? inLeft - rBL * getXVal(24) + 1 : 0; y: isActive(24) ? inBottom : 0; width: isActive(24) ? rBL * getXVal(24) : 0; height: isActive(24) ? rBL * getYo(24) : 0 }
    Region { x: isActive(25) ? inLeft - rBL * getXVal(25) + 1 : 0; y: isActive(25) ? inBottom : 0; width: isActive(25) ? rBL * getXVal(25) : 0; height: isActive(25) ? rBL * getYo(25) : 0 }
    Region { x: isActive(26) ? inLeft - rBL * getXVal(26) + 1 : 0; y: isActive(26) ? inBottom : 0; width: isActive(26) ? rBL * getXVal(26) : 0; height: isActive(26) ? rBL * getYo(26) : 0 }
    Region { x: isActive(27) ? inLeft - rBL * getXVal(27) + 1 : 0; y: isActive(27) ? inBottom : 0; width: isActive(27) ? rBL * getXVal(27) : 0; height: isActive(27) ? rBL * getYo(27) : 0 }
    Region { x: isActive(28) ? inLeft - rBL * getXVal(28) + 1 : 0; y: isActive(28) ? inBottom : 0; width: isActive(28) ? rBL * getXVal(28) : 0; height: isActive(28) ? rBL * getYo(28) : 0 }
    Region { x: isActive(29) ? inLeft - rBL * getXVal(29) + 1 : 0; y: isActive(29) ? inBottom : 0; width: isActive(29) ? rBL * getXVal(29) : 0; height: isActive(29) ? rBL * getYo(29) : 0 }
    Region { x: isActive(30) ? inLeft - rBL * getXVal(30) + 1 : 0; y: isActive(30) ? inBottom : 0; width: isActive(30) ? rBL * getXVal(30) : 0; height: isActive(30) ? rBL * getYo(30) : 0 }
    Region { x: isActive(31) ? inLeft - rBL * getXVal(31) + 1 : 0; y: isActive(31) ? inBottom : 0; width: isActive(31) ? rBL * getXVal(31) : 0; height: isActive(31) ? rBL * getYo(31) : 0 }
    Region { x: isActive(32) ? inLeft - rBL * getXVal(32) + 1 : 0; y: isActive(32) ? inBottom : 0; width: isActive(32) ? rBL * getXVal(32) : 0; height: isActive(32) ? rBL * getYo(32) : 0 }
    Region { x: isActive(33) ? inLeft - rBL * getXVal(33) + 1 : 0; y: isActive(33) ? inBottom : 0; width: isActive(33) ? rBL * getXVal(33) : 0; height: isActive(33) ? rBL * getYo(33) : 0 }
    Region { x: isActive(34) ? inLeft - rBL * getXVal(34) + 1 : 0; y: isActive(34) ? inBottom : 0; width: isActive(34) ? rBL * getXVal(34) : 0; height: isActive(34) ? rBL * getYo(34) : 0 }
    Region { x: isActive(35) ? inLeft - rBL * getXVal(35) + 1 : 0; y: isActive(35) ? inBottom : 0; width: isActive(35) ? rBL * getXVal(35) : 0; height: isActive(35) ? rBL * getYo(35) : 0 }
    Region { x: isActive(36) ? inLeft - rBL * getXVal(36) + 1 : 0; y: isActive(36) ? inBottom : 0; width: isActive(36) ? rBL * getXVal(36) : 0; height: isActive(36) ? rBL * getYo(36) : 0 }
    Region { x: isActive(37) ? inLeft - rBL * getXVal(37) + 1 : 0; y: isActive(37) ? inBottom : 0; width: isActive(37) ? rBL * getXVal(37) : 0; height: isActive(37) ? rBL * getYo(37) : 0 }
    Region { x: isActive(38) ? inLeft - rBL * getXVal(38) + 1 : 0; y: isActive(38) ? inBottom : 0; width: isActive(38) ? rBL * getXVal(38) : 0; height: isActive(38) ? rBL * getYo(38) : 0 }
    Region { x: isActive(39) ? inLeft - rBL * getXVal(39) + 1 : 0; y: isActive(39) ? inBottom : 0; width: isActive(39) ? rBL * getXVal(39) : 0; height: isActive(39) ? rBL * getYo(39) : 0 }
    Region { x: isActive(40) ? inLeft - rBL * getXVal(40) + 1 : 0; y: isActive(40) ? inBottom : 0; width: isActive(40) ? rBL * getXVal(40) : 0; height: isActive(40) ? rBL * getYo(40) : 0 }
    Region { x: isActive(41) ? inLeft - rBL * getXVal(41) + 1 : 0; y: isActive(41) ? inBottom : 0; width: isActive(41) ? rBL * getXVal(41) : 0; height: isActive(41) ? rBL * getYo(41) : 0 }
    Region { x: isActive(42) ? inLeft - rBL * getXVal(42) + 1 : 0; y: isActive(42) ? inBottom : 0; width: isActive(42) ? rBL * getXVal(42) : 0; height: isActive(42) ? rBL * getYo(42) : 0 }
    Region { x: isActive(43) ? inLeft - rBL * getXVal(43) + 1 : 0; y: isActive(43) ? inBottom : 0; width: isActive(43) ? rBL * getXVal(43) : 0; height: isActive(43) ? rBL * getYo(43) : 0 }
    Region { x: isActive(44) ? inLeft - rBL * getXVal(44) + 1 : 0; y: isActive(44) ? inBottom : 0; width: isActive(44) ? rBL * getXVal(44) : 0; height: isActive(44) ? rBL * getYo(44) : 0 }
    Region { x: isActive(45) ? inLeft - rBL * getXVal(45) + 1 : 0; y: isActive(45) ? inBottom : 0; width: isActive(45) ? rBL * getXVal(45) : 0; height: isActive(45) ? rBL * getYo(45) : 0 }
    Region { x: isActive(46) ? inLeft - rBL * getXVal(46) + 1 : 0; y: isActive(46) ? inBottom : 0; width: isActive(46) ? rBL * getXVal(46) : 0; height: isActive(46) ? rBL * getYo(46) : 0 }
    Region { x: isActive(47) ? inLeft - rBL * getXVal(47) + 1 : 0; y: isActive(47) ? inBottom : 0; width: isActive(47) ? rBL * getXVal(47) : 0; height: isActive(47) ? rBL * getYo(47) : 0 }
    Region { x: isActive(48) ? inLeft - rBL * getXVal(48) + 1 : 0; y: isActive(48) ? inBottom : 0; width: isActive(48) ? rBL * getXVal(48) : 0; height: isActive(48) ? rBL * getYo(48) : 0 }
    Region { x: isActive(49) ? inLeft - rBL * getXVal(49) + 1 : 0; y: isActive(49) ? inBottom : 0; width: isActive(49) ? rBL * getXVal(49) : 0; height: isActive(49) ? rBL * getYo(49) : 0 }
    Region { x: isActive(50) ? inLeft - rBL * getXVal(50) + 1 : 0; y: isActive(50) ? inBottom : 0; width: isActive(50) ? rBL * getXVal(50) : 0; height: isActive(50) ? rBL * getYo(50) : 0 }
    Region { x: isActive(51) ? inLeft - rBL * getXVal(51) + 1 : 0; y: isActive(51) ? inBottom : 0; width: isActive(51) ? rBL * getXVal(51) : 0; height: isActive(51) ? rBL * getYo(51) : 0 }
    Region { x: isActive(52) ? inLeft - rBL * getXVal(52) + 1 : 0; y: isActive(52) ? inBottom : 0; width: isActive(52) ? rBL * getXVal(52) : 0; height: isActive(52) ? rBL * getYo(52) : 0 }
    Region { x: isActive(53) ? inLeft - rBL * getXVal(53) + 1 : 0; y: isActive(53) ? inBottom : 0; width: isActive(53) ? rBL * getXVal(53) : 0; height: isActive(53) ? rBL * getYo(53) : 0 }
    Region { x: isActive(54) ? inLeft - rBL * getXVal(54) + 1 : 0; y: isActive(54) ? inBottom : 0; width: isActive(54) ? rBL * getXVal(54) : 0; height: isActive(54) ? rBL * getYo(54) : 0 }
    Region { x: isActive(55) ? inLeft - rBL * getXVal(55) + 1 : 0; y: isActive(55) ? inBottom : 0; width: isActive(55) ? rBL * getXVal(55) : 0; height: isActive(55) ? rBL * getYo(55) : 0 }
    Region { x: isActive(56) ? inLeft - rBL * getXVal(56) + 1 : 0; y: isActive(56) ? inBottom : 0; width: isActive(56) ? rBL * getXVal(56) : 0; height: isActive(56) ? rBL * getYo(56) : 0 }
    Region { x: isActive(57) ? inLeft - rBL * getXVal(57) + 1 : 0; y: isActive(57) ? inBottom : 0; width: isActive(57) ? rBL * getXVal(57) : 0; height: isActive(57) ? rBL * getYo(57) : 0 }
    Region { x: isActive(58) ? inLeft - rBL * getXVal(58) + 1 : 0; y: isActive(58) ? inBottom : 0; width: isActive(58) ? rBL * getXVal(58) : 0; height: isActive(58) ? rBL * getYo(58) : 0 }
    Region { x: isActive(59) ? inLeft - rBL * getXVal(59) + 1 : 0; y: isActive(59) ? inBottom : 0; width: isActive(59) ? rBL * getXVal(59) : 0; height: isActive(59) ? rBL * getYo(59) : 0 }
    Region { x: isActive(60) ? inLeft - rBL * getXVal(60) + 1 : 0; y: isActive(60) ? inBottom : 0; width: isActive(60) ? rBL * getXVal(60) : 0; height: isActive(60) ? rBL * getYo(60) : 0 }
    Region { x: isActive(61) ? inLeft - rBL * getXVal(61) + 1 : 0; y: isActive(61) ? inBottom : 0; width: isActive(61) ? rBL * getXVal(61) : 0; height: isActive(61) ? rBL * getYo(61) : 0 }
    Region { x: isActive(62) ? inLeft - rBL * getXVal(62) + 1 : 0; y: isActive(62) ? inBottom : 0; width: isActive(62) ? rBL * getXVal(62) : 0; height: isActive(62) ? rBL * getYo(62) : 0 }
    Region { x: isActive(63) ? inLeft - rBL * getXVal(63) + 1 : 0; y: isActive(63) ? inBottom : 0; width: isActive(63) ? rBL * getXVal(63) : 0; height: isActive(63) ? rBL * getYo(63) : 0 }
    Region { x: isActive(64) ? inLeft - rBL * getXVal(64) + 1 : 0; y: isActive(64) ? inBottom : 0; width: isActive(64) ? rBL * getXVal(64) : 0; height: isActive(64) ? rBL * getYo(64) : 0 }
    Region { x: isActive(65) ? inLeft - rBL * getXVal(65) + 1 : 0; y: isActive(65) ? inBottom : 0; width: isActive(65) ? rBL * getXVal(65) : 0; height: isActive(65) ? rBL * getYo(65) : 0 }
    Region { x: isActive(66) ? inLeft - rBL * getXVal(66) + 1 : 0; y: isActive(66) ? inBottom : 0; width: isActive(66) ? rBL * getXVal(66) : 0; height: isActive(66) ? rBL * getYo(66) : 0 }
    Region { x: isActive(67) ? inLeft - rBL * getXVal(67) + 1 : 0; y: isActive(67) ? inBottom : 0; width: isActive(67) ? rBL * getXVal(67) : 0; height: isActive(67) ? rBL * getYo(67) : 0 }
    Region { x: isActive(68) ? inLeft - rBL * getXVal(68) + 1 : 0; y: isActive(68) ? inBottom : 0; width: isActive(68) ? rBL * getXVal(68) : 0; height: isActive(68) ? rBL * getYo(68) : 0 }
    Region { x: isActive(69) ? inLeft - rBL * getXVal(69) + 1 : 0; y: isActive(69) ? inBottom : 0; width: isActive(69) ? rBL * getXVal(69) : 0; height: isActive(69) ? rBL * getYo(69) : 0 }
    Region { x: isActive(70) ? inLeft - rBL * getXVal(70) + 1 : 0; y: isActive(70) ? inBottom : 0; width: isActive(70) ? rBL * getXVal(70) : 0; height: isActive(70) ? rBL * getYo(70) : 0 }
    Region { x: isActive(71) ? inLeft - rBL * getXVal(71) + 1 : 0; y: isActive(71) ? inBottom : 0; width: isActive(71) ? rBL * getXVal(71) : 0; height: isActive(71) ? rBL * getYo(71) : 0 }
    Region { x: isActive(72) ? inLeft - rBL * getXVal(72) + 1 : 0; y: isActive(72) ? inBottom : 0; width: isActive(72) ? rBL * getXVal(72) : 0; height: isActive(72) ? rBL * getYo(72) : 0 }
    Region { x: isActive(73) ? inLeft - rBL * getXVal(73) + 1 : 0; y: isActive(73) ? inBottom : 0; width: isActive(73) ? rBL * getXVal(73) : 0; height: isActive(73) ? rBL * getYo(73) : 0 }
    Region { x: isActive(74) ? inLeft - rBL * getXVal(74) + 1 : 0; y: isActive(74) ? inBottom : 0; width: isActive(74) ? rBL * getXVal(74) : 0; height: isActive(74) ? rBL * getYo(74) : 0 }
    Region { x: isActive(75) ? inLeft - rBL * getXVal(75) + 1 : 0; y: isActive(75) ? inBottom : 0; width: isActive(75) ? rBL * getXVal(75) : 0; height: isActive(75) ? rBL * getYo(75) : 0 }
    Region { x: isActive(76) ? inLeft - rBL * getXVal(76) + 1 : 0; y: isActive(76) ? inBottom : 0; width: isActive(76) ? rBL * getXVal(76) : 0; height: isActive(76) ? rBL * getYo(76) : 0 }
    Region { x: isActive(77) ? inLeft - rBL * getXVal(77) + 1 : 0; y: isActive(77) ? inBottom : 0; width: isActive(77) ? rBL * getXVal(77) : 0; height: isActive(77) ? rBL * getYo(77) : 0 }
    Region { x: isActive(78) ? inLeft - rBL * getXVal(78) + 1 : 0; y: isActive(78) ? inBottom : 0; width: isActive(78) ? rBL * getXVal(78) : 0; height: isActive(78) ? rBL * getYo(78) : 0 }
    Region { x: isActive(79) ? inLeft - rBL * getXVal(79) + 1 : 0; y: isActive(79) ? inBottom : 0; width: isActive(79) ? rBL * getXVal(79) : 0; height: isActive(79) ? rBL * getYo(79) : 0 }
    Region { x: isActive(80) ? inLeft - rBL * getXVal(80) + 1 : 0; y: isActive(80) ? inBottom : 0; width: isActive(80) ? rBL * getXVal(80) : 0; height: isActive(80) ? rBL * getYo(80) : 0 }
    Region { x: isActive(81) ? inLeft - rBL * getXVal(81) + 1 : 0; y: isActive(81) ? inBottom : 0; width: isActive(81) ? rBL * getXVal(81) : 0; height: isActive(81) ? rBL * getYo(81) : 0 }
    Region { x: isActive(82) ? inLeft - rBL * getXVal(82) + 1 : 0; y: isActive(82) ? inBottom : 0; width: isActive(82) ? rBL * getXVal(82) : 0; height: isActive(82) ? rBL * getYo(82) : 0 }
    Region { x: isActive(83) ? inLeft - rBL * getXVal(83) + 1 : 0; y: isActive(83) ? inBottom : 0; width: isActive(83) ? rBL * getXVal(83) : 0; height: isActive(83) ? rBL * getYo(83) : 0 }
    Region { x: isActive(84) ? inLeft - rBL * getXVal(84) + 1 : 0; y: isActive(84) ? inBottom : 0; width: isActive(84) ? rBL * getXVal(84) : 0; height: isActive(84) ? rBL * getYo(84) : 0 }
    Region { x: isActive(85) ? inLeft - rBL * getXVal(85) + 1 : 0; y: isActive(85) ? inBottom : 0; width: isActive(85) ? rBL * getXVal(85) : 0; height: isActive(85) ? rBL * getYo(85) : 0 }
    Region { x: isActive(86) ? inLeft - rBL * getXVal(86) + 1 : 0; y: isActive(86) ? inBottom : 0; width: isActive(86) ? rBL * getXVal(86) : 0; height: isActive(86) ? rBL * getYo(86) : 0 }
    Region { x: isActive(87) ? inLeft - rBL * getXVal(87) + 1 : 0; y: isActive(87) ? inBottom : 0; width: isActive(87) ? rBL * getXVal(87) : 0; height: isActive(87) ? rBL * getYo(87) : 0 }
    Region { x: isActive(88) ? inLeft - rBL * getXVal(88) + 1 : 0; y: isActive(88) ? inBottom : 0; width: isActive(88) ? rBL * getXVal(88) : 0; height: isActive(88) ? rBL * getYo(88) : 0 }
    Region { x: isActive(89) ? inLeft - rBL * getXVal(89) + 1 : 0; y: isActive(89) ? inBottom : 0; width: isActive(89) ? rBL * getXVal(89) : 0; height: isActive(89) ? rBL * getYo(89) : 0 }
    Region { x: isActive(90) ? inLeft - rBL * getXVal(90) + 1 : 0; y: isActive(90) ? inBottom : 0; width: isActive(90) ? rBL * getXVal(90) : 0; height: isActive(90) ? rBL * getYo(90) : 0 }
    Region { x: isActive(91) ? inLeft - rBL * getXVal(91) + 1 : 0; y: isActive(91) ? inBottom : 0; width: isActive(91) ? rBL * getXVal(91) : 0; height: isActive(91) ? rBL * getYo(91) : 0 }
    Region { x: isActive(92) ? inLeft - rBL * getXVal(92) + 1 : 0; y: isActive(92) ? inBottom : 0; width: isActive(92) ? rBL * getXVal(92) : 0; height: isActive(92) ? rBL * getYo(92) : 0 }
    Region { x: isActive(93) ? inLeft - rBL * getXVal(93) + 1 : 0; y: isActive(93) ? inBottom : 0; width: isActive(93) ? rBL * getXVal(93) : 0; height: isActive(93) ? rBL * getYo(93) : 0 }
    Region { x: isActive(94) ? inLeft - rBL * getXVal(94) + 1 : 0; y: isActive(94) ? inBottom : 0; width: isActive(94) ? rBL * getXVal(94) : 0; height: isActive(94) ? rBL * getYo(94) : 0 }
    Region { x: isActive(95) ? inLeft - rBL * getXVal(95) + 1 : 0; y: isActive(95) ? inBottom : 0; width: isActive(95) ? rBL * getXVal(95) : 0; height: isActive(95) ? rBL * getYo(95) : 0 }
    Region { x: isActive(96) ? inLeft - rBL * getXVal(96) + 1 : 0; y: isActive(96) ? inBottom : 0; width: isActive(96) ? rBL * getXVal(96) : 0; height: isActive(96) ? rBL * getYo(96) : 0 }
    Region { x: isActive(97) ? inLeft - rBL * getXVal(97) + 1 : 0; y: isActive(97) ? inBottom : 0; width: isActive(97) ? rBL * getXVal(97) : 0; height: isActive(97) ? rBL * getYo(97) : 0 }
    Region { x: isActive(98) ? inLeft - rBL * getXVal(98) + 1 : 0; y: isActive(98) ? inBottom : 0; width: isActive(98) ? rBL * getXVal(98) : 0; height: isActive(98) ? rBL * getYo(98) : 0 }
    Region { x: isActive(99) ? inLeft - rBL * getXVal(99) + 1 : 0; y: isActive(99) ? inBottom : 0; width: isActive(99) ? rBL * getXVal(99) : 0; height: isActive(99) ? rBL * getYo(99) : 0 }
    Region { x: isActive(100) ? inLeft - rBL * getXVal(100) + 1 : 0; y: isActive(100) ? inBottom : 0; width: isActive(100) ? rBL * getXVal(100) : 0; height: isActive(100) ? rBL * getYo(100) : 0 }

    // Bottom-Right Outer Corner
    Region { x: isActive(1) ? inRight : 0; y: isActive(1) ? inBottom : 0; width: isActive(1) ? rBR * getXVal(1) : 0; height: isActive(1) ? rBR * getYo(1) : 0 }
    Region { x: isActive(2) ? inRight : 0; y: isActive(2) ? inBottom : 0; width: isActive(2) ? rBR * getXVal(2) : 0; height: isActive(2) ? rBR * getYo(2) : 0 }
    Region { x: isActive(3) ? inRight : 0; y: isActive(3) ? inBottom : 0; width: isActive(3) ? rBR * getXVal(3) : 0; height: isActive(3) ? rBR * getYo(3) : 0 }
    Region { x: isActive(4) ? inRight : 0; y: isActive(4) ? inBottom : 0; width: isActive(4) ? rBR * getXVal(4) : 0; height: isActive(4) ? rBR * getYo(4) : 0 }
    Region { x: isActive(5) ? inRight : 0; y: isActive(5) ? inBottom : 0; width: isActive(5) ? rBR * getXVal(5) : 0; height: isActive(5) ? rBR * getYo(5) : 0 }
    Region { x: isActive(6) ? inRight : 0; y: isActive(6) ? inBottom : 0; width: isActive(6) ? rBR * getXVal(6) : 0; height: isActive(6) ? rBR * getYo(6) : 0 }
    Region { x: isActive(7) ? inRight : 0; y: isActive(7) ? inBottom : 0; width: isActive(7) ? rBR * getXVal(7) : 0; height: isActive(7) ? rBR * getYo(7) : 0 }
    Region { x: isActive(8) ? inRight : 0; y: isActive(8) ? inBottom : 0; width: isActive(8) ? rBR * getXVal(8) : 0; height: isActive(8) ? rBR * getYo(8) : 0 }
    Region { x: isActive(9) ? inRight : 0; y: isActive(9) ? inBottom : 0; width: isActive(9) ? rBR * getXVal(9) : 0; height: isActive(9) ? rBR * getYo(9) : 0 }
    Region { x: isActive(10) ? inRight : 0; y: isActive(10) ? inBottom : 0; width: isActive(10) ? rBR * getXVal(10) : 0; height: isActive(10) ? rBR * getYo(10) : 0 }
    Region { x: isActive(11) ? inRight : 0; y: isActive(11) ? inBottom : 0; width: isActive(11) ? rBR * getXVal(11) : 0; height: isActive(11) ? rBR * getYo(11) : 0 }
    Region { x: isActive(12) ? inRight : 0; y: isActive(12) ? inBottom : 0; width: isActive(12) ? rBR * getXVal(12) : 0; height: isActive(12) ? rBR * getYo(12) : 0 }
    Region { x: isActive(13) ? inRight : 0; y: isActive(13) ? inBottom : 0; width: isActive(13) ? rBR * getXVal(13) : 0; height: isActive(13) ? rBR * getYo(13) : 0 }
    Region { x: isActive(14) ? inRight : 0; y: isActive(14) ? inBottom : 0; width: isActive(14) ? rBR * getXVal(14) : 0; height: isActive(14) ? rBR * getYo(14) : 0 }
    Region { x: isActive(15) ? inRight : 0; y: isActive(15) ? inBottom : 0; width: isActive(15) ? rBR * getXVal(15) : 0; height: isActive(15) ? rBR * getYo(15) : 0 }
    Region { x: isActive(16) ? inRight : 0; y: isActive(16) ? inBottom : 0; width: isActive(16) ? rBR * getXVal(16) : 0; height: isActive(16) ? rBR * getYo(16) : 0 }
    Region { x: isActive(17) ? inRight : 0; y: isActive(17) ? inBottom : 0; width: isActive(17) ? rBR * getXVal(17) : 0; height: isActive(17) ? rBR * getYo(17) : 0 }
    Region { x: isActive(18) ? inRight : 0; y: isActive(18) ? inBottom : 0; width: isActive(18) ? rBR * getXVal(18) : 0; height: isActive(18) ? rBR * getYo(18) : 0 }
    Region { x: isActive(19) ? inRight : 0; y: isActive(19) ? inBottom : 0; width: isActive(19) ? rBR * getXVal(19) : 0; height: isActive(19) ? rBR * getYo(19) : 0 }
    Region { x: isActive(20) ? inRight : 0; y: isActive(20) ? inBottom : 0; width: isActive(20) ? rBR * getXVal(20) : 0; height: isActive(20) ? rBR * getYo(20) : 0 }
    Region { x: isActive(21) ? inRight : 0; y: isActive(21) ? inBottom : 0; width: isActive(21) ? rBR * getXVal(21) : 0; height: isActive(21) ? rBR * getYo(21) : 0 }
    Region { x: isActive(22) ? inRight : 0; y: isActive(22) ? inBottom : 0; width: isActive(22) ? rBR * getXVal(22) : 0; height: isActive(22) ? rBR * getYo(22) : 0 }
    Region { x: isActive(23) ? inRight : 0; y: isActive(23) ? inBottom : 0; width: isActive(23) ? rBR * getXVal(23) : 0; height: isActive(23) ? rBR * getYo(23) : 0 }
    Region { x: isActive(24) ? inRight : 0; y: isActive(24) ? inBottom : 0; width: isActive(24) ? rBR * getXVal(24) : 0; height: isActive(24) ? rBR * getYo(24) : 0 }
    Region { x: isActive(25) ? inRight : 0; y: isActive(25) ? inBottom : 0; width: isActive(25) ? rBR * getXVal(25) : 0; height: isActive(25) ? rBR * getYo(25) : 0 }
    Region { x: isActive(26) ? inRight : 0; y: isActive(26) ? inBottom : 0; width: isActive(26) ? rBR * getXVal(26) : 0; height: isActive(26) ? rBR * getYo(26) : 0 }
    Region { x: isActive(27) ? inRight : 0; y: isActive(27) ? inBottom : 0; width: isActive(27) ? rBR * getXVal(27) : 0; height: isActive(27) ? rBR * getYo(27) : 0 }
    Region { x: isActive(28) ? inRight : 0; y: isActive(28) ? inBottom : 0; width: isActive(28) ? rBR * getXVal(28) : 0; height: isActive(28) ? rBR * getYo(28) : 0 }
    Region { x: isActive(29) ? inRight : 0; y: isActive(29) ? inBottom : 0; width: isActive(29) ? rBR * getXVal(29) : 0; height: isActive(29) ? rBR * getYo(29) : 0 }
    Region { x: isActive(30) ? inRight : 0; y: isActive(30) ? inBottom : 0; width: isActive(30) ? rBR * getXVal(30) : 0; height: isActive(30) ? rBR * getYo(30) : 0 }
    Region { x: isActive(31) ? inRight : 0; y: isActive(31) ? inBottom : 0; width: isActive(31) ? rBR * getXVal(31) : 0; height: isActive(31) ? rBR * getYo(31) : 0 }
    Region { x: isActive(32) ? inRight : 0; y: isActive(32) ? inBottom : 0; width: isActive(32) ? rBR * getXVal(32) : 0; height: isActive(32) ? rBR * getYo(32) : 0 }
    Region { x: isActive(33) ? inRight : 0; y: isActive(33) ? inBottom : 0; width: isActive(33) ? rBR * getXVal(33) : 0; height: isActive(33) ? rBR * getYo(33) : 0 }
    Region { x: isActive(34) ? inRight : 0; y: isActive(34) ? inBottom : 0; width: isActive(34) ? rBR * getXVal(34) : 0; height: isActive(34) ? rBR * getYo(34) : 0 }
    Region { x: isActive(35) ? inRight : 0; y: isActive(35) ? inBottom : 0; width: isActive(35) ? rBR * getXVal(35) : 0; height: isActive(35) ? rBR * getYo(35) : 0 }
    Region { x: isActive(36) ? inRight : 0; y: isActive(36) ? inBottom : 0; width: isActive(36) ? rBR * getXVal(36) : 0; height: isActive(36) ? rBR * getYo(36) : 0 }
    Region { x: isActive(37) ? inRight : 0; y: isActive(37) ? inBottom : 0; width: isActive(37) ? rBR * getXVal(37) : 0; height: isActive(37) ? rBR * getYo(37) : 0 }
    Region { x: isActive(38) ? inRight : 0; y: isActive(38) ? inBottom : 0; width: isActive(38) ? rBR * getXVal(38) : 0; height: isActive(38) ? rBR * getYo(38) : 0 }
    Region { x: isActive(39) ? inRight : 0; y: isActive(39) ? inBottom : 0; width: isActive(39) ? rBR * getXVal(39) : 0; height: isActive(39) ? rBR * getYo(39) : 0 }
    Region { x: isActive(40) ? inRight : 0; y: isActive(40) ? inBottom : 0; width: isActive(40) ? rBR * getXVal(40) : 0; height: isActive(40) ? rBR * getYo(40) : 0 }
    Region { x: isActive(41) ? inRight : 0; y: isActive(41) ? inBottom : 0; width: isActive(41) ? rBR * getXVal(41) : 0; height: isActive(41) ? rBR * getYo(41) : 0 }
    Region { x: isActive(42) ? inRight : 0; y: isActive(42) ? inBottom : 0; width: isActive(42) ? rBR * getXVal(42) : 0; height: isActive(42) ? rBR * getYo(42) : 0 }
    Region { x: isActive(43) ? inRight : 0; y: isActive(43) ? inBottom : 0; width: isActive(43) ? rBR * getXVal(43) : 0; height: isActive(43) ? rBR * getYo(43) : 0 }
    Region { x: isActive(44) ? inRight : 0; y: isActive(44) ? inBottom : 0; width: isActive(44) ? rBR * getXVal(44) : 0; height: isActive(44) ? rBR * getYo(44) : 0 }
    Region { x: isActive(45) ? inRight : 0; y: isActive(45) ? inBottom : 0; width: isActive(45) ? rBR * getXVal(45) : 0; height: isActive(45) ? rBR * getYo(45) : 0 }
    Region { x: isActive(46) ? inRight : 0; y: isActive(46) ? inBottom : 0; width: isActive(46) ? rBR * getXVal(46) : 0; height: isActive(46) ? rBR * getYo(46) : 0 }
    Region { x: isActive(47) ? inRight : 0; y: isActive(47) ? inBottom : 0; width: isActive(47) ? rBR * getXVal(47) : 0; height: isActive(47) ? rBR * getYo(47) : 0 }
    Region { x: isActive(48) ? inRight : 0; y: isActive(48) ? inBottom : 0; width: isActive(48) ? rBR * getXVal(48) : 0; height: isActive(48) ? rBR * getYo(48) : 0 }
    Region { x: isActive(49) ? inRight : 0; y: isActive(49) ? inBottom : 0; width: isActive(49) ? rBR * getXVal(49) : 0; height: isActive(49) ? rBR * getYo(49) : 0 }
    Region { x: isActive(50) ? inRight : 0; y: isActive(50) ? inBottom : 0; width: isActive(50) ? rBR * getXVal(50) : 0; height: isActive(50) ? rBR * getYo(50) : 0 }
    Region { x: isActive(51) ? inRight : 0; y: isActive(51) ? inBottom : 0; width: isActive(51) ? rBR * getXVal(51) : 0; height: isActive(51) ? rBR * getYo(51) : 0 }
    Region { x: isActive(52) ? inRight : 0; y: isActive(52) ? inBottom : 0; width: isActive(52) ? rBR * getXVal(52) : 0; height: isActive(52) ? rBR * getYo(52) : 0 }
    Region { x: isActive(53) ? inRight : 0; y: isActive(53) ? inBottom : 0; width: isActive(53) ? rBR * getXVal(53) : 0; height: isActive(53) ? rBR * getYo(53) : 0 }
    Region { x: isActive(54) ? inRight : 0; y: isActive(54) ? inBottom : 0; width: isActive(54) ? rBR * getXVal(54) : 0; height: isActive(54) ? rBR * getYo(54) : 0 }
    Region { x: isActive(55) ? inRight : 0; y: isActive(55) ? inBottom : 0; width: isActive(55) ? rBR * getXVal(55) : 0; height: isActive(55) ? rBR * getYo(55) : 0 }
    Region { x: isActive(56) ? inRight : 0; y: isActive(56) ? inBottom : 0; width: isActive(56) ? rBR * getXVal(56) : 0; height: isActive(56) ? rBR * getYo(56) : 0 }
    Region { x: isActive(57) ? inRight : 0; y: isActive(57) ? inBottom : 0; width: isActive(57) ? rBR * getXVal(57) : 0; height: isActive(57) ? rBR * getYo(57) : 0 }
    Region { x: isActive(58) ? inRight : 0; y: isActive(58) ? inBottom : 0; width: isActive(58) ? rBR * getXVal(58) : 0; height: isActive(58) ? rBR * getYo(58) : 0 }
    Region { x: isActive(59) ? inRight : 0; y: isActive(59) ? inBottom : 0; width: isActive(59) ? rBR * getXVal(59) : 0; height: isActive(59) ? rBR * getYo(59) : 0 }
    Region { x: isActive(60) ? inRight : 0; y: isActive(60) ? inBottom : 0; width: isActive(60) ? rBR * getXVal(60) : 0; height: isActive(60) ? rBR * getYo(60) : 0 }
    Region { x: isActive(61) ? inRight : 0; y: isActive(61) ? inBottom : 0; width: isActive(61) ? rBR * getXVal(61) : 0; height: isActive(61) ? rBR * getYo(61) : 0 }
    Region { x: isActive(62) ? inRight : 0; y: isActive(62) ? inBottom : 0; width: isActive(62) ? rBR * getXVal(62) : 0; height: isActive(62) ? rBR * getYo(62) : 0 }
    Region { x: isActive(63) ? inRight : 0; y: isActive(63) ? inBottom : 0; width: isActive(63) ? rBR * getXVal(63) : 0; height: isActive(63) ? rBR * getYo(63) : 0 }
    Region { x: isActive(64) ? inRight : 0; y: isActive(64) ? inBottom : 0; width: isActive(64) ? rBR * getXVal(64) : 0; height: isActive(64) ? rBR * getYo(64) : 0 }
    Region { x: isActive(65) ? inRight : 0; y: isActive(65) ? inBottom : 0; width: isActive(65) ? rBR * getXVal(65) : 0; height: isActive(65) ? rBR * getYo(65) : 0 }
    Region { x: isActive(66) ? inRight : 0; y: isActive(66) ? inBottom : 0; width: isActive(66) ? rBR * getXVal(66) : 0; height: isActive(66) ? rBR * getYo(66) : 0 }
    Region { x: isActive(67) ? inRight : 0; y: isActive(67) ? inBottom : 0; width: isActive(67) ? rBR * getXVal(67) : 0; height: isActive(67) ? rBR * getYo(67) : 0 }
    Region { x: isActive(68) ? inRight : 0; y: isActive(68) ? inBottom : 0; width: isActive(68) ? rBR * getXVal(68) : 0; height: isActive(68) ? rBR * getYo(68) : 0 }
    Region { x: isActive(69) ? inRight : 0; y: isActive(69) ? inBottom : 0; width: isActive(69) ? rBR * getXVal(69) : 0; height: isActive(69) ? rBR * getYo(69) : 0 }
    Region { x: isActive(70) ? inRight : 0; y: isActive(70) ? inBottom : 0; width: isActive(70) ? rBR * getXVal(70) : 0; height: isActive(70) ? rBR * getYo(70) : 0 }
    Region { x: isActive(71) ? inRight : 0; y: isActive(71) ? inBottom : 0; width: isActive(71) ? rBR * getXVal(71) : 0; height: isActive(71) ? rBR * getYo(71) : 0 }
    Region { x: isActive(72) ? inRight : 0; y: isActive(72) ? inBottom : 0; width: isActive(72) ? rBR * getXVal(72) : 0; height: isActive(72) ? rBR * getYo(72) : 0 }
    Region { x: isActive(73) ? inRight : 0; y: isActive(73) ? inBottom : 0; width: isActive(73) ? rBR * getXVal(73) : 0; height: isActive(73) ? rBR * getYo(73) : 0 }
    Region { x: isActive(74) ? inRight : 0; y: isActive(74) ? inBottom : 0; width: isActive(74) ? rBR * getXVal(74) : 0; height: isActive(74) ? rBR * getYo(74) : 0 }
    Region { x: isActive(75) ? inRight : 0; y: isActive(75) ? inBottom : 0; width: isActive(75) ? rBR * getXVal(75) : 0; height: isActive(75) ? rBR * getYo(75) : 0 }
    Region { x: isActive(76) ? inRight : 0; y: isActive(76) ? inBottom : 0; width: isActive(76) ? rBR * getXVal(76) : 0; height: isActive(76) ? rBR * getYo(76) : 0 }
    Region { x: isActive(77) ? inRight : 0; y: isActive(77) ? inBottom : 0; width: isActive(77) ? rBR * getXVal(77) : 0; height: isActive(77) ? rBR * getYo(77) : 0 }
    Region { x: isActive(78) ? inRight : 0; y: isActive(78) ? inBottom : 0; width: isActive(78) ? rBR * getXVal(78) : 0; height: isActive(78) ? rBR * getYo(78) : 0 }
    Region { x: isActive(79) ? inRight : 0; y: isActive(79) ? inBottom : 0; width: isActive(79) ? rBR * getXVal(79) : 0; height: isActive(79) ? rBR * getYo(79) : 0 }
    Region { x: isActive(80) ? inRight : 0; y: isActive(80) ? inBottom : 0; width: isActive(80) ? rBR * getXVal(80) : 0; height: isActive(80) ? rBR * getYo(80) : 0 }
    Region { x: isActive(81) ? inRight : 0; y: isActive(81) ? inBottom : 0; width: isActive(81) ? rBR * getXVal(81) : 0; height: isActive(81) ? rBR * getYo(81) : 0 }
    Region { x: isActive(82) ? inRight : 0; y: isActive(82) ? inBottom : 0; width: isActive(82) ? rBR * getXVal(82) : 0; height: isActive(82) ? rBR * getYo(82) : 0 }
    Region { x: isActive(83) ? inRight : 0; y: isActive(83) ? inBottom : 0; width: isActive(83) ? rBR * getXVal(83) : 0; height: isActive(83) ? rBR * getYo(83) : 0 }
    Region { x: isActive(84) ? inRight : 0; y: isActive(84) ? inBottom : 0; width: isActive(84) ? rBR * getXVal(84) : 0; height: isActive(84) ? rBR * getYo(84) : 0 }
    Region { x: isActive(85) ? inRight : 0; y: isActive(85) ? inBottom : 0; width: isActive(85) ? rBR * getXVal(85) : 0; height: isActive(85) ? rBR * getYo(85) : 0 }
    Region { x: isActive(86) ? inRight : 0; y: isActive(86) ? inBottom : 0; width: isActive(86) ? rBR * getXVal(86) : 0; height: isActive(86) ? rBR * getYo(86) : 0 }
    Region { x: isActive(87) ? inRight : 0; y: isActive(87) ? inBottom : 0; width: isActive(87) ? rBR * getXVal(87) : 0; height: isActive(87) ? rBR * getYo(87) : 0 }
    Region { x: isActive(88) ? inRight : 0; y: isActive(88) ? inBottom : 0; width: isActive(88) ? rBR * getXVal(88) : 0; height: isActive(88) ? rBR * getYo(88) : 0 }
    Region { x: isActive(89) ? inRight : 0; y: isActive(89) ? inBottom : 0; width: isActive(89) ? rBR * getXVal(89) : 0; height: isActive(89) ? rBR * getYo(89) : 0 }
    Region { x: isActive(90) ? inRight : 0; y: isActive(90) ? inBottom : 0; width: isActive(90) ? rBR * getXVal(90) : 0; height: isActive(90) ? rBR * getYo(90) : 0 }
    Region { x: isActive(91) ? inRight : 0; y: isActive(91) ? inBottom : 0; width: isActive(91) ? rBR * getXVal(91) : 0; height: isActive(91) ? rBR * getYo(91) : 0 }
    Region { x: isActive(92) ? inRight : 0; y: isActive(92) ? inBottom : 0; width: isActive(92) ? rBR * getXVal(92) : 0; height: isActive(92) ? rBR * getYo(92) : 0 }
    Region { x: isActive(93) ? inRight : 0; y: isActive(93) ? inBottom : 0; width: isActive(93) ? rBR * getXVal(93) : 0; height: isActive(93) ? rBR * getYo(93) : 0 }
    Region { x: isActive(94) ? inRight : 0; y: isActive(94) ? inBottom : 0; width: isActive(94) ? rBR * getXVal(94) : 0; height: isActive(94) ? rBR * getYo(94) : 0 }
    Region { x: isActive(95) ? inRight : 0; y: isActive(95) ? inBottom : 0; width: isActive(95) ? rBR * getXVal(95) : 0; height: isActive(95) ? rBR * getYo(95) : 0 }
    Region { x: isActive(96) ? inRight : 0; y: isActive(96) ? inBottom : 0; width: isActive(96) ? rBR * getXVal(96) : 0; height: isActive(96) ? rBR * getYo(96) : 0 }
    Region { x: isActive(97) ? inRight : 0; y: isActive(97) ? inBottom : 0; width: isActive(97) ? rBR * getXVal(97) : 0; height: isActive(97) ? rBR * getYo(97) : 0 }
    Region { x: isActive(98) ? inRight : 0; y: isActive(98) ? inBottom : 0; width: isActive(98) ? rBR * getXVal(98) : 0; height: isActive(98) ? rBR * getYo(98) : 0 }
    Region { x: isActive(99) ? inRight : 0; y: isActive(99) ? inBottom : 0; width: isActive(99) ? rBR * getXVal(99) : 0; height: isActive(99) ? rBR * getYo(99) : 0 }
    Region { x: isActive(100) ? inRight : 0; y: isActive(100) ? inBottom : 0; width: isActive(100) ? rBR * getXVal(100) : 0; height: isActive(100) ? rBR * getYo(100) : 0 }
}
