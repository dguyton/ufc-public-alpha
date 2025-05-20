Data set of manual fan speed controllable Gigabtye server motherboards.

## Gigabyte Server Motherboards
| Model | Manual Fan<br>Control? | BMC | # Fan<br>Zones | # Fan<br>Headers | CPU<br>Fans | System<br>Fans |
| ----- |:---------------:| --- |:-----------:|:-------------:|:------:|:------:|
| [MW70-3S0](https://download.gigabyte.com/FileList/Manual/server_manual_mw70-3s0_e_1003.pdf">MW70-3S0) | ? | ASPEED AST2400 | 2 | 7 | 2 | 5 |
| WRX80-SU8-IPMI | No <sup>1</sup> | ASPEED AST2500 |  | 7 | 1 | 6 |
| G431-MM0 | No |
| G492-Z51 | No |
| GA-7TESM | ? |
| GA-7PESH1 | ? | ASPEED AST2300 |  | 6 | 2 | 4 |
| H262-Z62 | No |
| MD70-HB0 | No |
| MD71-HB0 (Intel C622) | No |
| MD72-HB0 | No |
| MX33-BS0 | No |

<sup>1</sup> Fans can only be controlled semi-manually via [GSM temperature thresholds](gigabyte-ipmi-commands.md#gsm-related-ipmi-commands).<br>

## Known Gigabyte servers with AST2500 BMC
The following Gigabyte server motherboard models have the ASPEED AST2500 BMC. Their compatibility with manual fan control is unknown, but due to their BMC chip it is possible.

G191-H44, G221-Z30, G291-280, G291-281, G291-2G0, G291-Z20, G481-H80, G481-H81, G481-HA0, G481-HA1, G481-S80, H231-G20, H231-H60, H261-3C0, H261-H60, H261-H61, H261-N80, H281-PE0, MB51-PS0, MD61-SC2, MD71-HB0, MF51-ES0, MF51-ES1, MF51-ES2, MZ31-AR0, R151-Z30, R161-R12, R161-R13, R181-2A0, R181-340, R181-N20, R181-NA0, R181-Z90, R181-Z91, R181-Z92, R271-Z31, R281-2O0, R281-3C0, R281-3C1, R281-3C2, R281-G30, R281-N40, R281-NO0, R281-Z91, R281-Z92, R281-Z94, S451-3R0, S451-Z30,  S461-3T0, R181-T90, R281-T91, R181-T92, R281-T94, MZ01-CEO
