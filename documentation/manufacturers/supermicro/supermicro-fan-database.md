# Supermicro Model Database
Database of Supermicro motherboard characteristics. This information is limited to server-class motherboards with a BMC chip.

## Supermicro Boards by Server Line and Generation
High-level overview of each series.

| Model Series | Socket | CPU Type | Max # CPUs | Release Year |
| ------------ | ------ | -------- |:----------:|:------------:|
| A1	| FCBGA 1283 | Intel Atom C2750 |	1 | 2024 |
| B2 | LGA 1155 |	Intel Core i3, Xeon E3-1200	| 1	| 2012 |
| B3 | LGA 1851 | Intel Core Ultra 7 (Series 2) | 1 | 2025 |
| C7	| LGA 1151	| Intel Xeon E3-1200 v6	| 1	| 2017 |
| C9	| LGA 1200	| Intel Core i9/i7/i5 (11th Gen)	| 1	| 2021 |
| H11 | SP3	| AMD EPYC 7001/7002| 2	| 2017 |
| H12	| SP3	| AMD EPYC 7002	| 2	| 2019 |
| H13	| SP5	| AMD EPYC 9004/9005 | 1 | 2023 |
| M11	| System-on-Chip | Intel Xeon D |	1 | 2019 |
| M12	| sWRX8	| AMD Ryzen Threadripper PRO 3000WX	| 1	| 2021
| X9 | LGA 2011	| Intel Xeon E5-2600/1600	| 2	| 2012 |
| X10	| LGA 2011-v3	| Intel Xeon E5-2600 v3	| 2	| 2014 |
| X11	| LGA 3647 | Intel Xeon Scalable | 2 | 2017 |
| X12	| LGA 4189 | Intel Xeon Scalable (3rd Gen) | 2 | 2021 |
| X13	| LGA 4677 | Intel Xeon Scalable (4th/5th Gen) | 2	| 2023 |
| X14	| LGA 1851 | Intel Core Ultra 9/7/5	| 1	| 2024 |

For server line descrptions, see [Supermicro Fan Control Compatibility by Server Line & Generation](supermicro-server-gens.md) article for more information about each model series.

## A1 Series Motherboards
The Supeermicro A1 series motherboards are very low-power server-class boards with Intel Atom processors.

| Model | Manual Fan<br>Control? | BMC | # Fan Zones | # Fan Headers | Zone 0<br>Fans | Zone 1<br>Fans |
| ----- |:---------------:| --- |:-----------:|:-------------:|:------:|:------:|
| [A1SAi-2358F](https://www.supermicro.com/manuals/motherboard/Atom_on-chip/MNL-1555.pdf) | Yes | ASPEED AST2400 | ? | 3 | ? | ? |
| [A1SAi-2550F](https://www.supermicro.com/manuals/motherboard/Atom_on-chip/MNL-1555.pdf) | Yes | ASPEED AST2400 | ? | 3 | ? | ? |
| [A1SAi-2558F](https://www.supermicro.com/manuals/motherboard/Atom_on-chip/MNL-1555.pdf) | Yes | ASPEED AST2400 | ? | 3 | ? | ? |
| [A1SAi-2750F](https://www.supermicro.com/manuals/motherboard/Atom_on-chip/MNL-1555.pdf) | Yes | ASPEED AST2400 | ? | 3 | ? | ? |
| [A1SAi-2758F](https://www.supermicro.com/manuals/motherboard/Atom_on-chip/MNL-1555.pdf) | Yes | ASPEED AST2400 | ? | 3 | ? | ? |

## B2, B3 Series Motherboards
| Model | Manual Fan<br>Control? | BMC | # Fan Zones | # Fan Headers | Zone 0<br>Fans | Zone 1<br>Fans |
| ----- |:---------------:| --- |:-----------:|:-------------:|:------:|:------:|
| B2SC1-CPU | No | ASPEED AST2500 |  |  |  |  |
| [B2SC2-TF](https://www.supermicro.com/manuals/motherboard/B2/MNL-2307.pdf) | No | ASPEED AST2500 |
| [B2SD1-8C-TF](https://www.supermicro.com/manuals/motherboard/D/MNL-2227.pdf) | No | ASPEED AST2500 |
| [B2SD1-12C-TF](https://www.supermicro.com/manuals/motherboard/D/MNL-2227.pdf) | No | ASPEED AST2500 |
| [B2SD1-16C-TF](https://www.supermicro.com/manuals/motherboard/D/MNL-2227.pdf) | No | ASPEED AST2500 |
| [B2SD2-8C-TF](https://www.supermicro.com/manuals/motherboard/D/MNL-2227.pdf) | No | ASPEED AST2500 |
| [B3ST1-CPU-001](https://www.supermicro.com/manuals/motherboard/B3/MNL-2430.pdf) | No | ASPEED AST2500 |

## B11, B12 Series Motherboards
| Model | Manual Fan<br>Control? | BMC | # Fan Zones | # Fan Headers | Zone 0<br>Fans | Zone 1<br>Fans |
| ----- |:---------------:| --- |:-----------:|:-------------:|:------:|:------:|
| [B11SCG-CTF](https://www.supermicro.com/manuals/motherboard/B11/MNL-2187.pdf) | No | ASPEED AST2500 |
| [B11SCG-ZTF](https://www.supermicro.com/manuals/motherboard/B11/MNL-2187.pdf) | No | ASPEED AST2500 |
| B11SPE-CPU-TF | No | ASPEED AST2500 |  |  |  |  |
| [B11SRE-CPU-TF](https://www.supermicro.com/manuals/motherboard/B11/MNL-2182.pdf) | No | ASPEED AST2500 |
| [B12SPE-CPU-25G](https://www.supermicro.com/manuals/motherboard/B12/MNL-2272.pdf) | No | ASPEED AST2600 |

## C7 Series Motherboards
| Model | Manual Fan<br>Control? | BMC | # Fan Zones | # Fan Headers | Zone 0<br>Fans | Zone 1<br>Fans |
| ----- |:---------------:| --- |:-----------:|:-------------:|:------:|:------:|
| [C7C232-CB-ML](https://www.supermicro.com/manuals/motherboard/C232/MNL-1906.pdf) | No |
| [C7C242-CB-M](https://www.supermicro.com/manuals/motherboard/C242/MNL-2097.pdf) | No |
| [C7C242-CB-MW](https://www.supermicro.com/manuals/motherboard/C242/MNL-2097.pdf) | No |  | 1 | 3 | 3 |
| [C7H170-M](https://www.supermicro.com/manuals/motherboard/Z170/MNL-1813.pdf) | No |  | 1 | 5 | 5 |
| [C7Q67](https://www.supermicro.com/manuals/motherboard/Q67/MNL-C7Q67.pdf) | No |  | 1 | 4 | 4 |
| [C7SIM-Q](https://www.supermicro.com/manuals/motherboard/Q57/MNL-1174.pdf) | No |  | 1 | 4 | 4 |
| [C7X99-OCE](https://www.supermicro.com/manuals/motherboard/X99/MNL-1646.pdf) | No |  | 1 | 5 | 5 |
| [C7X99-OCE-F](https://www.supermicro.com/manuals/motherboard/X99/MNL-1646.pdf) | ? | ASPEED AST2500 | 1 | 5 | 5 |
| [C7Z170-M](https://www.supermicro.com/manuals/motherboard/Z170/MNL-1813.pdf) | No |  | 1 | 5 | 5 |
| [C7Z170-SQ](https://www.supermicro.com/manuals/motherboard/Z170/MNL-1720.pdf) | No |  | 1 | 5  | 5 |

## C9 Series Motherboards
| Model | Manual Fan<br>Control? | BMC | # Fan Zones | # Fan Headers | Zone 0<br>Fans | Zone 1<br>Fans |
| ----- |:---------------:| --- |:-----------:|:-------------:|:------:|:------:|
| [C9X299-PG300](https://www.supermicro.com/manuals/motherboard/X299/MNL-2078.pdf) | No |  | 1 | 5  | 5 | 
| [C9X299-PG300F](https://www.supermicro.com/manuals/motherboard/X299/MNL-2117.pdf) | ? | ASPEED AST2500| 2 | 5| 2 | 3 |
| [C9X299-PGF](https://www.supermicro.com/manuals/motherboard/X299/MNL-2001.pdf) | ? | ASPEED AST2500 | 1 | 5 | 5 | 
| [C9X299-PGF-L](https://www.supermicro.com/manuals/motherboard/X299/MNL-2424.pdf) | ? | ASPEED AST2500| 2 | 5| 2 | 3 
| [C9X299-RPGF](https://www.supermicro.com/manuals/motherboard/X299/MNL-2001.pdf) | ? | ASPEED AST2500 | 1 | 5 | 5 |
| [C9X299-RPGF-L](https://www.supermicro.com/manuals/motherboard/X299/MNL-2424.pdf) | ? | ASPEED AST2500 | 1 | 5| 2 | 3 
| [C9Z390-CG](https://www.supermicro.com/manuals/motherboard/Z390/MNL-2098.pdf) | No |  | 1 | 5 | 5 |
| [C9Z390-CG-IW](https://www.supermicro.com/manuals/motherboard/Z390/MNL-2018.pdf) | No |  | 1| 2 |
| [C9Z390-CGW](https://www.supermicro.com/manuals/motherboard/Z390/MNL-2098.pdf) | No |  | 1  | 5  | 5 | 
| [C9Z390-PGW](https://www.supermicro.com/manuals/motherboard/Z390/MNL-2030.pdf) | No |  | 1  | 5  | 5 | 
| [C9Z490-PG](https://www.supermicro.com/manuals/motherboard/Z490/MNL-2238.pdf) | No | | 2 | 2 | 3 | 
| [C9Z490-PGW](https://www.supermicro.com/manuals/motherboard/Z490/MNL-2238.pdf)| No | | 2 | 2 | 3 | 
| [C9Z590-CG](https://www.supermicro.com/manuals/motherboard/Z590/MNL-2335.pdf) | No | | 2 | 2 | 3 | 
| [C9Z590-CGW](https://www.supermicro.com/manuals/motherboard/Z590/MNL-2335.pdf) | No | | 2 | 2 | 3 | 

## H11 Series Motherboards
| Model | Manual Fan<br>Control? | BMC | # Fan Zones | # Fan Headers | Zone 0<br>Fans | Zone 1<br>Fans |
| ----- |:---------------:| --- |:-----------:|:-------------:|:------:|:------:|
| [H11SSL-i](https://www.supermicro.com/manuals/motherboard/EPYC7000/MNL-2085.pdf) | Yes | ASPEED AST2500| 2 | 7 | 5| 2 |
| [H11SSL-C](https://www.supermicro.com/manuals/motherboard/EPYC7000/MNL-2085.pdf) | Yes | ASPEED AST2500| 2 | 7 | 5| 2 |
| [H11SSL-NC](https://www.supermicro.com/manuals/motherboard/EPYC7000/MNL-2085.pdf) | Yes | ASPEED AST2500| 2 | 7 | 5| 2 |

## H12 Series Motherboards
| Model | Manual Fan<br>Control? | BMC | # Fan Zones | # Fan Headers | Zone 0<br>Fans | Zone 1<br>Fans |
| ----- |:---------------:| --- |:-----------:|:-------------:|:------:|:------:|
| [H12SSL-i](https://www.supermicro.com/manuals/motherboard/EPYC7000/MNL-2314.pdf) | Yes | ASPEED AST2500| 2 | 7 | 5| 2 |
| [H12SSL-C](https://www.supermicro.com/manuals/motherboard/EPYC7000/MNL-2314.pdf) | Yes | ASPEED AST2500| 2 | 7 | 5| 2 |
| [H12SSL-CT](https://www.supermicro.com/manuals/motherboard/EPYC7000/MNL-2314.pdf) | Yes | ASPEED AST2500| 2 | 7 | 5| 2 |
| [H12SSL-NC](https://www.supermicro.com/manuals/motherboard/EPYC7000/MNL-2314.pdf) | Yes | ASPEED AST2500| 2 | 7 | 5| 2 |
| [H12SSW-NTR](https://www.supermicro.com/manuals/motherboard/EPYC7000/MNL-2284.pdf) | Yes | ASPEED AST2500 | 1 | 6 | 6 |

## M11, M12 Series Motherboards
| Model | Manual Fan<br>Control? | BMC | # Fan Zones | # Fan Headers | Zone 0<br>Fans | Zone 1<br>Fans |
| ----- |:---------------:| --- |:-----------:|:-------------:|:------:|:------:|
| M11SDV-8C+-LN4F | ? | ASPEED AST2500 | 1 | 3 |
| [M12SWA-TF](https://www.supermicro.com/manuals/motherboard/M12/MNL-2336.pdf) | ? | ASPEED AST2600| 2 | 10 | 6 | 4 |

## X8 Motherboards
| Model | Manual Fan<br>Control? | BMC | # Fan Zones | # Fan Headers | Zone 0<br>Fans | Zone 1<br>Fans |
| ----- |:---------------:| --- |:-----------:|:-------------:|:------:|:------:|
| [X8DAH+-F](https://www.supermicro.com/manuals/motherboard/5500/MNL-1060.pdf) | Maybe | Nuvuton WPCM450R  | 2| 8 | 6 | 2 |
| X8DTH-F | Maybe | Nuvoton W83795G |
| [X8DTi-F](https://www.nuvoton.com/resource-files/Nuvoton_W83795G_W83795ADG_Datasheet_V1.43.pdf) <sup>1</sup> | Maybe | Nuvoton W83795G |
| [X8DTL-iF](https://www.nuvoton.com/resource-files/Nuvoton_W83795G_W83795ADG_Datasheet_V1.43.pdf) <sup>1</sup> | Maybe | Nuvoton W83795G | 
| [X8DTL-3f](https://www.nuvoton.com/resource-files/Nuvoton_W83795G_W83795ADG_Datasheet_V1.43.pdf) | Maybe | Nuvoton W83795G |  | 14 |
| X8DTL-iF| Maybe | Nuvoton W83795G |
| [X8DTH-6](https://www.supermicro.com/manuals/motherboard/5500/MNL-1083.pdf) <sup>2</sup> | Maybe | Nuvuton WPCM450R  | 1| 8 |
| [X8DTH-6F](https://www.supermicro.com/manuals/motherboard/5500/MNL-1083.pdf) <sup>2</sup> | Maybe | Nuvuton WPCM450R  | 1| 8 |
| [X8DTH-i](https://www.supermicro.com/manuals/motherboard/5500/MNL-1083.pdf) <sup>2</sup> | Maybe | Nuvuton WPCM450R  | 1| 8 |
| [X8DTH-iF](https://www.supermicro.com/manuals/motherboard/5500/MNL-1083.pdf) <sup>2</sup> | Maybe | Nuvuton WPCM450R  | 1| 8 |

## X9 Motherboards
| Model | Manual Fan<br>Control? | BMC | # Fan Zones | # Fan Headers | Zone 0<br>Fans | Zone 1<br>Fans |
| ----- |:---------------:| --- |:-----------:|:-------------:|:------:|:------:|
| [X9DR3-F](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1259.pdf) | Yes | Nuvuton WPCM450 | 2 | 12 | 10 | 2 |
| [X9DR7-LN4F](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1336.pdf) | ? | Nuvuton WPCM450R | 2 | 8 | 6 | 2 |
| [X9DR7-LN4F-JBOD](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1336.pdf) | ? | Nuvuton WPCM450R | 2 | 8 | 6 | 2 |
| X9DR3-LN4F+ | ? | Nuvuton WPCM450  | 2| 8 | 6 | 2 |
| [X9DRD-EF](https://www.supermicro.com/QuickRefs/motherboard/C606_602/QRG-1412.pdf) | No | Nuvuton WPCM450 | 1| 8 | 8 |
| X9DRD-CNT+ | No | Nuvuton WPCM450 | 1 | 6 | 6 | 
| X9DRD-CT+ | No | Nuvuton WPCM450 | 1 | 6 | 6 | 
| [X9DRD-EF](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1412.pdf) | No | Nuvuton WPCM450 | 1 | 8 | 8 |
| [X9DRD-7JLN4F](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1318.pdf) | No | Nuvuton WPCM450 | 1 | 8 | 8 |
| [X9DRD-7FLN4-EF](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1412.pdf) | No | Nuvuton WPCM450 | 1 | 8 | 8 |
| [X9DRD-7LN4F](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1318.pdf) | No | Nuvuton WPCM450 | 1 | 8 | 8 |
| X9DRD-7LN4F-JBOD | No | Nuvuton WPCM450 | 1 | 8 | 8 |
| [X9DRD-iF](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1488.pdf) | No | Nuvuton WPCM450 | 1 | 8 | 8 |
| X9DRD-iT+ | No | Nuvuton WPCM450 | 1 | 6 | 6 |
| [X9DRD-LF](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1488.pdf) | No | Nuvuton WPCM450 | 1 | 8 | 8 |
| [X9DRE-LN4F](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1336.pdf) | Yes | Nuvuton WPCM450R | 2 | 8 | 6 | 2 |
| [X9DRG-OF](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-X9DRG-of-platform.pdf) | ? | Nuvuton WPCM450 | 1 | 8 | 8 |
| X9DRG-O-PCIE | ? | Nuvuton WPCM450 |  | 5 |
| [X9DRG-QF](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1309.pdf) | ? | Renesas SH7757 | 1 | 8 | 8 |
| [X9DRH-7F](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1306.pdf) | No | Nuvuton WPCM450R | 2 | 8 | 6 | 2 |
| X9DRH-iF | ? | Nuvoton WPCM450R | 2 | 8 | 6 | 2 |
| X9DRH-iF-NV | ? | Nuvoton WPCM450R | 2 | 8 | 6 | 2 |
| X9DRH-7TF | ? | Nuvoton WPCM450R | 2 | 8 | 6 | 2 |
| X9DRH-iTF | ? | Nuvoton WPCM450R | 2 | 8 | 6 | 2 |
| [X9DRi-F](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1259.pdf) | Yes | Nuvuton WPCM450 | 2 | 12 | 10 | 2 |
| X9DRi-LN4F+ | ? | Nuvuton WPCM450 | 2 | 8 | 6 | 2 |
| [X9DRW-3F](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1278.pdf) | ? | Renesas SH7757 | 2 | 6 | 4 | 2 |
| X9DRW-CTF31 | ? |
| [X9DRW-iF](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1278.pdf) | ? | Renesas SH7757 | 2 | 6 | 4 | 2 |
| [X9SCA](https://www.supermicro.com/manuals/motherboard/C202_C204/MNL-1283.pdf) | No |
| [X9SCA-F](https://www.supermicro.com/manuals/motherboard/C202_C204/MNL-1283.pdf) | ? | Nuvuton WPCM450 | 2 | 5 | 4 | 1 |
| [X9QR7-TF+](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1324.pdf) | ? | Nuvuton WPCM450R | 1 | 10 |
| [X9QRi-F+](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1324.pdf) | ? | Nuvuton WPCM450R | 1 | 10 |
| [X9QR7-TF](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1370.pdf) | ? | Nuvuton WPCM450 | 2 | 8 | 4 | 4 |
| [X9QR7-TF-JBOD](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1370.pdf) | ? | Nuvuton WPCM450 | 2 | 8 | 4 | 4 |
| [X9QRi-F](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1370.pdf) | ? | Nuvuton WPCM450 | 2 | 8 | 4 | 4 |
| [X9SAE](https://www.supermicro.com/manuals/motherboard/C216/MNL-1356.pdf) | No |  | 2 | 5 | 4 | 1 |
| [X9SAE-V](https://www.supermicro.com/manuals/motherboard/C216/MNL-1356.pdf) | No | | 2 | 5 | 4 | 1 |
| [X9SBAA](https://www.supermicro.com/manuals/motherboard/Atom_on-chip/MNL-1480.pdf) | ? | Nuvoton WPCM450 | 1 | 3 | 3 |
| [X9SBAA-F](https://www.supermicro.com/manuals/motherboard/Atom_on-chip/MNL-1480.pdf) | ? | Nuvoton WPCM450 | 1 | 3 | 3 | 
| [X9SCA](https://www.supermicro.com/manuals/motherboard/C202_C204/MNL-1283.pdf) | No |
| [X9SCA-F](https://www.supermicro.com/manuals/motherboard/C202_C204/MNL-1283.pdf) | ? | Nuvoton WPCM450 | 2 | 5 | 4 | 1 |
| [X9SCi-LN4F](https://www.supermicro.com/manuals/motherboard/C202_C204/MNL-1283.pdf) | ? | Nuvoton WPCM450 | 2 | 5 | 4 | 1 |
| [X9SCi-LN4](https://www.supermicro.com/manuals/motherboard/C202_C204/MNL-1283.pdf) | No |
| X9SCD+-F | No |
| X9SCD+-HF | No |
| [X9SCD-F](https://www.supermicro.com/manuals/motherboard/C202_C204/MNL-1303.pdf) | No |
| [X9SCE-F](https://www.supermicro.com/manuals/motherboard/C202_C204/MNL-X9SCE-F.pdf) | No |
| [X9SCFF-F](https://www.supermicro.com/manuals/motherboard/C202_C204/MNL-1481.pdf) | No |  | 1 | 8 |
| [X9SCL](https://www.supermicro.com/manuals/motherboard/C202_C204/MNL-1270.pdf) <sup>3</sup> | No | Nuvoton WPCM450 | 2 | 4 | 1 |
| [X9SCL+-F](https://www.supermicro.com/manuals/motherboard/C202_C204/MNL-1270.pdf) <sup>3, 4</sup> | ? | Nuvoton WPCM450 | 2 | 4 | 1 |
| [X9SCL-F](https://www.supermicro.com/manuals/motherboard/C202_C204/MNL-1270.pdf) <sup>3, 4</sup> | No | Nuvoton WPCM450 | 2 | 5 | 4 | 1 |
| [X9SCL-IIF](https://www.supermicro.com/manuals/motherboard/C202_C204/MNL-1311.pdf) <sup>3</sup> | ? | Nuvoton WPCM450 | 2 | 4 | 1 |
| [X9SCM](https://www.supermicro.com/manuals/motherboard/C202_C204/MNL-1270.pdf) | Yes | Nuvoton WPCM450 | 2 | 4 | 1 |
| [X9SCM-F](https://www.supermicro.com/manuals/motherboard/C202_C204/MNL-1270.pdf) | ? | Nuvoton WPCM450 | 2 | 4 | 1 |
| [X9SCM-IIF](https://www.supermicro.com/manuals/motherboard/C202_C204/MNL-1311.pdf) | ? | Nuvoton WPCM450 | 2 | 4 | 1 |
| [X9SCV-Q](https://www.supermicro.com/manuals/motherboard/C202_C204/MNL-1285.pdf) | No |  | 1 | 3 | 3 |
| [X9SCV-QV4](https://www.supermicro.com/manuals/motherboard/C202_C204/MNL-1285.pdf) | No |  | 1 | 3 | 3 |
| [X9SRD-F](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1316.pdf) | No | Nuvoton WPCM450 |
| [X9SRE](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1284.pdf) | ? | Nuvoton WPCM450 | 2 | 5 | 4 | 1 |
| [X9SRE-3F](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1284.pdf) | ? | Nuvoton WPCM450 | 2 | 5 | 4 | 1 |
| [X9SRE-F](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1284.pdf) | ? | Nuvoton WPCM450 | 2 | 5 | 4 | 1 |
| [X9SRG-F](https://www.supermicro.com/manuals/motherboard/C600/MNL-1320.pdf) | No |  | 2 | 8 | 4 | 4 |
| [X9SRH-7F](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-X9SRH.pdf) | ? | Nuvoton WPCM450 | 2 | 5 | 4 | 1 |
| [X9SRH-7TF](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-X9SRH.pdf) | ? | Nuvoton WPCM450 | 2 | 5 | 4 | 1 |
| [X9SRi](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1284.pdf) | ? | Nuvoton WPCM450 | 2 | 5 | 4 | 1 |
| [X9SRi-3F](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1284.pdf) | ? | Nuvoton WPCM450 | 2 | 5 | 4 | 1 |
| [X9SRi-F](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1284.pdf) | ? | Nuvoton WPCM450 | 2 | 5 | 4 | 1 |
| [X9SRL](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1317.pdf) | No | Nuvoton WPCM450 | 2 | 5 | 4 | 1 |
| [X9SRL-F](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1317.pdf) | No | Nuvoton WPCM450 | 2 | 5 | 4 | 1 |
| [X9SRW-F](https://www.supermicro.com/manuals/motherboard/C600/MNL-1319.pdf) | No |  | 1 | 5 | 5 | 

## X10 Motherboards
| Model | Manual Fan<br>Control? | BMC | # Fan Zones | # Fan Headers | Zone 0<br>Fans | Zone 1<br>Fans |
| ----- |:---------------:| --- |:-----------:|:-------------:|:------:|:------:|
| [X10DAC](https://www.supermicro.com/manuals/motherboard/C612/MNL-1563.pdf) | ? |  | 2 | 8 | 7 | 1 |
| [X10DAi](https://www.supermicro.com/manuals/motherboard/C612/MNL-1563.pdf) | ? |  | 2 | 8 | 7 | 1 |
| [X10DAX](https://www.supermicro.com/manuals/motherboard/C612/MNL-1563.pdf) | No |  | 2 | 8 | 7 | 1 |
| [X10DRC-T4+](https://www.supermicro.com/manuals/motherboard/C600/MNL-1560.pdf) | Yes | ASPEED AST2400 | 2 | 9 | 6 | 3 |
| [X10DRC-LN4+](https://www.supermicro.com/manuals/motherboard/C600/MNL-1560.pdf) | ? | ASPEED AST2400 | 2 | 9 | 6 | 3 |
| [X10DRi-T4+](https://www.supermicro.com/manuals/motherboard/C600/MNL-1560.pdf) | ? | ASPEED AST2400 | 2 | 9 | 6 | 3 |
| [X10DRL-i](https://www.supermicro.com/manuals/motherboard/C600/MNL-1566.pdf) | Yes | ASPEED AST2400 | 2 | 8 | 6 | 2 |
| [X10DRi-LN4+](https://www.supermicro.com/manuals/motherboard/C600/MNL-1560.pdf) | ? | ASPEED AST2400 | 2 | 9 | 6 | 3 |
| [X10DRU-i+](https://www.supermicro.com/manuals/motherboard/C612/MNL-1597.pdf) | ? | ASPEED AST2400 | 1 | 8 | 8 |
| X10DRX | ? | 
| [X10OBI-CPU](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1866.pdf) | ? | Nuvoton WPCM450 |
| [X10OBI-PCH](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1866.pdf) | ? | ASPEED AST2400 |
| [X10QBi](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1802.pdf) | ? | ASPEED AST2400 | 1 | 10 | 10 |
| [X10QBL](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1680.pdf) | ? | ASPEED AST2400 | 1 | 10 | 10 |
| [X10QBL-CT ](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1680.pdf)| ? | ASPEED AST2400 | 1 | 10 | 10 |
| [X10QBL-4](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1833.pdf) | ? | ASPEED AST2400 | 1 | 10 | 10 |
| [X10QBL-4CT](https://www.supermicro.com/manuals/motherboard/C606_602/MNL-1833.pdf) | ? | ASPEED AST2400 | 1 | 10 | 10 |
| [X10QRH+](https://www.supermicro.com/manuals/motherboard/C612/MNL-1633.pdf) | ? | ASPEED AST2400 | 1 | 10 | 10 |
| [X10SBA](https://www.supermicro.com/manuals/motherboard/J1900/MNL-1553.pdf) | ? |  | 1 | 2 | 2 |
| [X10SBA-L](https://www.supermicro.com/manuals/motherboard/J1900/MNL-1553.pdf) | ? |  | 1 | 2 | 2 |
| [X10SBA-V](https://www.supermicro.com/manuals/motherboard/J1900/MNL-1553.pdf) | ? |  | 1 | 2 | 2 | 
| X10SDD-16C-F | No | 
| [X10SDD-F](https://www.supermicro.com/manuals/motherboard/D/MNL-1839.pdf) | No | ASPEED AST2400 |
| [X10SDE-DF](https://www.supermicro.com/manuals/motherboard/System-On-Chip/MNL-1875.pdf) | No | ASPEED AST2400 |
| X10SDV-12C-TLN4F | ? | ASPEED AST2400 |  | 4 | 
| [X10SDV-12C-TLN4F+](https://www.supermicro.com/manuals/motherboard/System-On-Chip/MNL-1903.pdf) | ? | ASPEED AST2400 | 2 | 3 | 1 |
| [X10SDV-12C+-TLN4F](https://www.supermicro.com/manuals/motherboard/D/MNL-1726.pdf) | ? | ASPEED AST2400 | 1 | 4 | 4 |
| X10SDV-12C+-TP8F | ? | ASPEED AST2400 |  | 6 |
| [X10SDV-16C-TLN4F](https://www.supermicro.com/manuals/motherboard/D/MNL-1726.pdf) | ? | ASPEED AST2400 | 1 | 3 | 3 |
| [X10SDV-16C-TLN4F+](https://www.supermicro.com/manuals/motherboard/System-On-Chip/MNL-1903.pdf) | ? | ASPEED AST2400 | 2 | 3 | 1 |
| [X10SDV-16C+-TLN4F](https://www.supermicro.com/manuals/motherboard/D/MNL-1726.pdf) | ? | ASPEED AST2400 | 1 | 4 | 4 |
| [X10SDV-2C-7TP4F](https://www.supermicro.com/manuals/motherboard/D/MNL-1858.pdf) | ? | ASPEED AST2400 | 2 | 4 | 2 |
| [X10SDV-2C-TLN2F](https://www.supermicro.com/manuals/motherboard/D/MNL-1726.pdf) | ? | ASPEED AST2400 | 1 | 4 | 4 |
| [X10SDV-2C-TP4F](https://www.supermicro.com/manuals/motherboard/D/MNL-1858.pdf) | ? | ASPEED AST2400 | 2 | 4 | 2 |
| [X10SDV-2C-TP8F](https://www.supermicro.com/manuals/motherboard/D/MNL-1858.pdf) | ? | ASPEED AST2400 | 2 | 4 | 2 |
| [X10SDV-4C+-TLN4F](https://www.supermicro.com/manuals/motherboard/D/MNL-1726.pdf) | ? | ASPEED AST2400 | 1 | 4 | 4 |
| [X10SDV-4C+-TP4F](https://www.supermicro.com/manuals/motherboard/D/MNL-1858.pdf) | ? | ASPEED AST2400 | 2 | 4 | 2 |
| [X10SDV-4C-7TP4F](https://www.supermicro.com/manuals/motherboard/D/MNL-1858.pdf) | ? | ASPEED AST2400 | 2 | 4 | 2 |
| [X10SDV-4C-TLN2F](https://www.supermicro.com/manuals/motherboard/D/MNL-1726.pdf) | ? | ASPEED AST2400 | 1 | 4 | 4 |
| [X10SDV-4C-TLN4F](https://www.supermicro.com/manuals/motherboard/D/MNL-1726.pdf) | ? | ASPEED AST2400 | 1 | 4 | 4 |
| [X10SDV-6C-TLN4F](https://www.supermicro.com/manuals/motherboard/D/MNL-1726.pdf) | ? | ASPEED AST2400 | 1 | 4 | 4 |
| [X10SDV-6C+-TLN4F](https://www.supermicro.com/manuals/motherboard/D/MNL-1726.pdf) | ? | ASPEED AST2400 | 1 | 4 | 4 |
| [X10SDV-8C+-LN2F](https://www.supermicro.com/manuals/motherboard/D/MNL-1726.pdf) | ? | ASPEED AST2400 | 1 | 4 | 4 |
| X10SDV-8C-TLN4F | ? | ASPEED AST2400 | 1 | 4 | 4 |
| X10SDV-8C-TLN4F+ | ? | ASPEED AST2400 | 2 | 3 | 1 |
| [X10SDV-12C-TLN4F+](https://www.supermicro.com/manuals/motherboard/System-On-Chip/MNL-1903.pdf) | ? | ASPEED AST2400 | 2 | 3 | 1 |
| [X10SDV-16C-TLN4F+](https://www.supermicro.com/manuals/motherboard/System-On-Chip/MNL-1903.pdf) | ? | ASPEED AST2400 | 2 | 3 | 1 |
| [X10SDV-F](https://www.supermicro.com/manuals/motherboard/D/MNL-1726.pdf) | ? | ASPEED AST2400 | 1 | 3 | 3 |
| [X10SDV-TLN4F](https://www.supermicro.com/manuals/motherboard/D/MNL-1726.pdf) | ? | ASPEED AST2400 | 1 | 3 | 3 |
| [X10SDV](https://www.supermicro.com/manuals/motherboard/D/MNL-1858.pdf) | ? | ASPEED AST2400 | 2 | 4 | 2 |
| X10SL7-F | No | ASPEED AST2400 | 2 | 5 | 4 | 1 |
| [X10SLD-F](https://www.supermicro.com/manuals/motherboard/C224/MNL-1485.pdf) | No | ASPEED AST2400 |
| [X10SLD-HF](https://www.supermicro.com/manuals/motherboard/C224/MNL-1485.pdf) | No | ASPEED AST2400 |
| [X10SLE-DF](https://www.supermicro.com/manuals/motherboard/C224/MNL-1558.pdf) | No | ASPEED AST2400 |
| [X10SLE-F](https://www.supermicro.com/manuals/motherboard/C224/MNL-1486.pdf) | No | ASPEED AST2400 |
| [X10SLE-HF](https://www.supermicro.com/manuals/motherboard/C224/MNL-1486.pdf) | No | ASPEED AST2400 |
| [X10SLQ](https://www.supermicro.com/manuals/motherboard/Q87/MNL-1478.pdf) | No |  | 1 | 4 | 4 |
| [X10SLQ-L](https://www.supermicro.com/manuals/motherboard/Q87/MNL-1478.pdf) | No | | 1 | 4 | 4 |
| [X10SLV](https://www.supermicro.com/manuals/motherboard/H81/MNL_1515.pdf) | No | | 1 | 3 | 3 |
| [X10SLV-Q](https://www.supermicro.com/manuals/motherboard/H81/MNL_1515.pdf) | No |  | 1 | 3 | 3 |
| [X10SRD-F](https://www.supermicro.com/manuals/motherboard/C600/MNL-1732.pdf) | ? | ASPEED AST2400 | 1 | 1 | 1 |
| X10SRH-C | Yes |
| X10SRI-F | Yes | ASPEED AST2400 | 1 |
| X10SRL-F | Yes |
| X10SRW-F | Yes |  | 1 |

## X11 Motherboards
| Model | Manual Fan<br>Control? | BMC | # Fan Zones | # Fan Headers | Zone 0<br>Fans | Zone 1<br>Fans |
| ----- |:---------------:| --- |:-----------:|:-------------:|:------:|:------:|
| X11DGP-SN | ? | ASPEED AST2500 | 2 | 12 | 4 | 8 |
| [X11QPH+](https://www.supermicro.com/manuals/motherboard/C620/MNL-1983.pdf) | ? | ASPEED AST2500 | 1 | 10 | 10 | 
| [X11DAC](https://www.supermicro.com/manuals/motherboard/C620/MNL-2082.pdf) | ? | ASPEED AST2500 | 2 | 7 | 6 | 1 |
| [X11DAi-N](https://www.supermicro.com/manuals/motherboard/C600/MNL-1957.pdf) | ? | ASPEED AST2500 | 2 | 7 | 6 | 1 |
| [X11DDW-NT](https://www.supermicro.com/manuals/motherboard/C620/MNL-1907.pdf) | ? | ASPEED AST2500 | 1 | 6 | 6 | 
| [X11DDW-L](https://www.supermicro.com/manuals/motherboard/C620/MNL-1907.pdf) | ? | ASPEED AST2500 | 1 | 6 | 6 | 
| [X11DGO-T](https://www.supermicro.com/manuals/motherboard/C620/MNL-2048.pdf) | ? | ASPEED AST2500 | 1 | 2 | 2 | 
| [X11DPFR-SN](https://www.supermicro.com/manuals/motherboard/C620/MNL-2021.pdf) | ? | ASPEED AST2500 | 1 | 3 | 3 | 
| [X11DPFR-S](https://www.supermicro.com/manuals/motherboard/C620/MNL-2021.pdf) | ? | ASPEED AST2500 | 1 | 3 | 3 | 
| [X11DPG-QT](https://www.supermicro.com/manuals/motherboard/C620/MNL-1998.pdf) | ? | ASPEED AST2500 | 2 | 10 | 6 | 4 |
| [X11DPH-i](https://www.supermicro.com/manuals/motherboard/C620/MNL-1912.pdf) | ? | ASPEED AST2500 | 2 | 8 | 6 | 2 |
| [X11DPH-T](https://www.supermicro.com/manuals/motherboard/C620/MNL-1912.pdf) | ? | ASPEED AST2500 | 2 | 8 | 6 | 2 |
| [X11DPH-TQ](https://www.supermicro.com/manuals/motherboard/C620/MNL-1912.pdf) | ? | ASPEED AST2500 | 2 | 8 | 6 | 2 |
| [X11DPi-N](https://www.supermicro.com/manuals/motherboard/C620/MNL-1773.pdf) | ? | ASPEED AST2500 | 2 | 10 | 8 | 2 |
| [X11DPi-NT](https://www.supermicro.com/manuals/motherboard/C620/MNL-1773.pdf) | ? | ASPEED AST2500 | 2 | 10 | 8 | 2 |
| [X11DPL-i](https://www.supermicro.com/manuals/motherboard/C620/MNL-1946.pdf) | ? | ASPEED AST2500 | 2 | 8 | 6 | 2 |
| [X11DPS-RE](https://www.supermicro.com/manuals/motherboard/C620/MNL-2144.pdf) | ? | ASPEED AST2500 | 1 | 8 |
| [X11DPT-B](https://www.supermicro.com/manuals/motherboard/C620/MNL-2020.pdf) | ? | ASPEED AST2500 | 1 | 2 | 2 | 
| [X11DPT-BH](https://www.supermicro.com/manuals/motherboard/C620/MNL-2127.pdf) | ? | ASPEED AST2500 | 2 | 6 | 2 | 4 |
| [X11DPT-L](https://www.supermicro.com/manuals/motherboard/C620/MNL-2154.pdf) | No | ASPEED AST2500 |
| [X11DPT-PS](https://www.supermicro.com/manuals/motherboard/C620/MNL-1911.pdf) | ? | ASPEED AST2500 | 1 | 1 | 1 | 
| [X11DPU](https://www.supermicro.com/manuals/motherboard/C620/MNL-1865.pdf) | ? | ASPEED AST2500 | 1 | 8 | 8 | 
| [X11DPU-NEBS](https://www.supermicro.com/manuals/motherboard/C620/MNL-1865.pdf) | ? | ASPEED AST2500 | 1 | 8 | 8 | 
| [X11DPU-V](https://www.supermicro.com/manuals/motherboard/C620/MNL-1865.pdf) | ? | ASPEED AST2500 | 1 | 8 | 8 | 
| X11DPU-Z+ | ? | ASPEED AST2500 | 1 | 8 | 8 | 
| [X11DPU-XLL](https://www.supermicro.com/manuals/motherboard/C620/MNL-1897.pdf) | ? | ASPEED AST2500 | 1 | 8 | 8 | 
| [X11DPU-X](https://www.supermicro.com/manuals/motherboard/C620/MNL-1897.pdf) | ? | ASPEED AST2500 | 1 | 8 | 8 | 
| [X11DPX-T](https://www.supermicro.com/manuals/motherboard/C620/MNL-2006.pdf) | ? | ASPEED AST2500 | 2 | 10 | 6 | 4 |
| [X11DSC+](https://www.supermicro.com/manuals/motherboard/C620/MNL-2073.pdf) | ? | ASPEED AST2500 | 1 | 5  | 5 | 
| [X11DSF-E](https://www.supermicro.com/manuals/motherboard/C620/MNL-2132.pdf) | ? | ASPEED AST2500 | 1 | 8 | 8 | 
| [X11OPi-CPU](https://www.supermicro.com/manuals/motherboard/C620/MNL-1982.pdf) | No | ASPEED AST2500 | 
| [X11SAE](https://www.supermicro.com/manuals/motherboard/C236/MNL-1820.pdf) | No | | 1 | 5 | 5 | 
| [X11SAE-F](https://www.supermicro.com/manuals/motherboard/C236/MNL-1820.pdf) | ? | ASPEED AST2400 | 1  | 5  | 5 | 
| [X11SAE-M](https://www.supermicro.com/manuals/motherboard/C236/MNL-1819.pdf) | No |  | 1  | 5 | 5 | 
| [X11SAT](https://www.supermicro.com/manuals/motherboard/C236/MNL-1823.pdf) | No |  | 1 | 5  | 5 | 
| [X11SAT-F](https://www.supermicro.com/manuals/motherboard/C236/MNL-1823.pdf) | ? | ASPEED AST2400 | 1  | 5  | 5 | 
| [X11SCA](https://www.supermicro.com/manuals/motherboard/X11/MNL-2087.pdf) | ? | ASPEED AST2500 | 2 | 5 | 2 | 3 |
| [X11SCA-F](https://www.supermicro.com/manuals/motherboard/X11/MNL-2087.pdf) | ? | ASPEED AST2500 | 2 | 5 | 2 | 3 |
| [X11SCA-W](https://www.supermicro.com/manuals/motherboard/X11/MNL-2087.pdf) | ? | ASPEED AST2500 | 2 | 5 | 2 | 3 |
| [X11SPA-T](https://www.supermicro.com/manuals/motherboard/C620/MNL-2173.pdf) | ? | ASPEED AST2500 | 2 | 10 | 6 | 4 |
| [X11SPA-TF](https://www.supermicro.com/manuals/motherboard/C620/MNL-2173.pdf) | ? | ASPEED AST2500 | 2 | 10 | 6 | 4 |
| [X11SPD-F](https://www.supermicro.com/manuals/motherboard/C620/MNL-2203.pdf) | ? | ASPEED AST2500 | 1 | 1 | 1 |
| [X11SCE-F](https://www.supermicro.com/manuals/motherboard/X11/MNL-2084.pdf) | No | ASPEED AST2500 |
| [X11SCH-F](https://www.supermicro.com/manuals/motherboard/X11/MNL-2105.pdf) | Yes | ASPEED AST2500 | 2 | 6 | 4 | 2 |
| [X11SCH-LN4F](https://www.supermicro.com/manuals/motherboard/X11/MNL-2105.pdf) | ? | ASPEED AST2500 | 2 | 6 | 4 | 2 
| [X11SCL-F](https://www.supermicro.com/manuals/motherboard/X11/MNL-2063.pdf) | ? | ASPEED AST2500 | 2 | 5 | 4 | 1 |
| [X11SCL-IF](https://www.supermicro.com/manuals/motherboard/X11/MNL-2088.pdf) | ? | ASPEED AST2500 | 2 | 4 | 3 | 1 |
| [X11SCL-LN4F](https://www.supermicro.com/manuals/motherboard/X11/MNL-2075.pdf) | ? | ASPEED AST2500 | 2 | 6 | 4 | 2 |
| [X11SCM-F](https://www.supermicro.com/manuals/motherboard/X11/MNL-2075.pdf) | ? | ASPEED AST2500 | 2 | 6 | 4 | 2 |
| [X11SCM-LN8F](https://www.supermicro.com/manuals/motherboard/X11/MNL-2075.pdf) | ? | ASPEED AST2500 | 2 | 6 | 4 | 2 |
| [X11SCW-F](https://www.supermicro.com/manuals/motherboard/X11/MNL-2070.pdf) | ? | ASPEED AST2500 | 1 | 6 | 6 |
| [X11SCZ-F](https://www.supermicro.com/manuals/motherboard/X11/MNL-2086.pdf) | ? | ASPEED AST2500 | 2 | 6 | 4 | 2 |
| [X11SCZ-Q](https://www.supermicro.com/manuals/motherboard/X11/MNL-2086.pdf) | No |  | 2 | 6 | 4 | 2 |
| [X11SPA-T](https://www.supermicro.com/manuals/motherboard/C620/MNL-2173.pdf) | ? | ASPEED AST2500 | 2 | 10 | 6 | 4 |
| [X11SPA-TF](https://www.supermicro.com/manuals/motherboard/C620/MNL-2173.pdf) | ? | ASPEED AST2500 | 2 | 10 | 6 | 4 |
| [X11SPD-F](https://www.supermicro.com/manuals/motherboard/C620/MNL-2203.pdf) | ? | ASPEED AST2500 | 1 | 1 | 1 | 
| [X11SPG-TF](https://www.supermicro.com/manuals/motherboard/C620/MNL-1965.pdf) | ? | ASPEED AST2500 | 2 | 8 | 4 | 4 |
| [X11SPH-nCTPF](https://www.supermicro.com/manuals/motherboard/C620/MNL-1949.pdf) | ? | ASPEED AST2500 | 2 | 8 | 5 | 3 |
| [X11SPH-nCTF](https://www.supermicro.com/manuals/motherboard/C620/MNL-1949.pdf) | Yes | ASPEED AST2500 | 2 | 8 | 5 | 3 |
| [X11SPi-TF](https://www.supermicro.com/manuals/motherboard/C620/MNL-1900.pdf) | Yes | ASPEED AST2500 | 2 | 7 | 5 | 2 |
| [X11SPL-F](https://www.supermicro.com/manuals/motherboard/C620/MNL-1950.pdf) | ? | ASPEED AST2500 | 2 | 7 | 5 | 2 |
| [X11SPM-F](https://www.supermicro.com/manuals/motherboard/C620/MNL-1939.pdf) | ? | ASPEED AST2500 | 2 | 8 | 6 | 2 |
| [X11SPM-TF](https://www.supermicro.com/manuals/motherboard/C620/MNL-1939.pdf) | ? | ASPEED AST2500 | 2 | 8 | 6 | 2 |
| [X11SPM-TPF](https://www.supermicro.com/manuals/motherboard/C620/MNL-1939.pdf) | ? | ASPEED AST2500 | 2 | 8 | 6 | 2 |
| [X11SPW-CTF](https://www.supermicro.com/manuals/motherboard/C620/MNL-1916.pdf) | ? | ASPEED AST2500 | 1 | 7 | 7 |
| [X11SPW-TF](https://www.supermicro.com/manuals/motherboard/C620/MNL-1916.pdf) | ? | ASPEED AST2500 | 1 | 7 | 7 | 
| [X11SSA-F](https://www.supermicro.com/manuals/motherboard/C236/MNL-1777.pdf) | ? | ASPEED AST2400 | 2 | 5 | 4 | 1 |
| [X11SSD-F](https://www.supermicro.com/manuals/motherboard/C236/MNL-1831.pdf) | ? | ASPEED AST2400 | 1 | 1 | 1 | 
| [X11SSE-F](https://www.supermicro.com/manuals/motherboard/C236/MNL-1792.pdf) | No | ASPEED AST2400 |
| [X11SSH-F](https://www.supermicro.com/manuals/motherboard/C236/MNL-1778.pdf) | ? | ASPEED AST2400 | 2 | 5 | 4 | 1 |
| [X11SSH-LN4F](https://www.supermicro.com/manuals/motherboard/C236/MNL-1778.pdf) | ? | ASPEED AST2400 | 2 | 5 | 4 | 1 |
| [X11SSH-CTF](https://www.supermicro.com/manuals/motherboard/C236/MNL-1783.pdf) | ? | ASPEED AST2400 | 2 | 6 | 5 | 1 |
| [X11SSH-TF](https://www.supermicro.com/manuals/motherboard/C236/MNL-1783.pdf) | ? | ASPEED AST2400 | 2 | 6 | 5 | 1 |
| [X11SSi-LN4F](https://www.supermicro.com/manuals/motherboard/C236/MNL-1777.pdf) | Yes | ASPEED AST2400 | 2 | 5 | 4 | 1 |
| [X11SSL](https://www.supermicro.com/manuals/motherboard/C236/MNL-1785.pdf) | ? | ASPEED AST2400 | 2 | 5 | 4 | 1 |
| [X11SSL-F](https://www.supermicro.com/manuals/motherboard/C236/MNL-1785.pdf) | ? | ASPEED AST2400 | 2 | 5 | 4 | 1 |
| [X11SSL-CF](https://www.supermicro.com/manuals/motherboard/C232/MNL-1782.pdf) | ? | ASPEED AST2400 | 2 | 5 | 4 | 1 |
| [X11SSL-nF](https://www.supermicro.com/manuals/motherboard/C232/MNL-1782.pdf) | ? | ASPEED AST2400 | 2 | 5 | 4 | 1 |
| [X11SSM](https://www.supermicro.com/manuals/motherboard/C236/MNL-1785.pdf) | ? | ASPEED AST2400 | 2  | 5 | 4 | 1 |
| [X11SSM-F](https://www.supermicro.com/manuals/motherboard/C236/MNL-1785.pdf) | ? | ASPEED AST2400 | 2 | 5 | 4 | 1 |
| [X11SSW-4TF](https://www.supermicro.com/manuals/motherboard/C236/MNL-1925.pdf) | ? | ASPEED AST2400 | 1 | 6 | 6 |
| [X11SSW-F](https://www.supermicro.com/manuals/motherboard/C236/MNL-1784.pdf) | No | ASPEED AST2400 | 1 | 6 | 6 | 
| [X11SSW-TF](https://www.supermicro.com/manuals/motherboard/C236/MNL-1925.pdf) | ? | ASPEED AST2400 | 1 | 6 | 6 |
| [X11SSZ-F](https://www.supermicro.com/manuals/motherboard/C236/MNL-1744.pdf) | ? | ASPEED AST2400 | 2 | 6 | 4 | 2 |
| [X11SSZ-QF](https://www.supermicro.com/manuals/motherboard/C236/MNL-1744.pdf) | ? | ASPEED AST2400 | 2 | 6 | 4 | 2 |
| [X11SSZ-TLN4F](https://www.supermicro.com/manuals/motherboard/C236/MNL-1744.pdf) | ? | ASPEED AST2400 | 2 | 6 | 4 | 2 |

## X12 Motherboards
| Model | Manual Fan<br>Control? | BMC | # Fan Zones | # Fan Headers | Zone 0<br>Fans | Zone 1<br>Fans |
| ----- |:---------------:| --- |:-----------:|:-------------:|:------:|:------:|
| [X12SCA-F](https://www.supermicro.com/manuals/motherboard/X12/MNL-2263.pdf) | ? | ASPEED AST2500 | 2 | 5 | 3 | 2 |
| X12STW-F | ? | ASPEED AST2600 | 1 | 6 |
| X12STW-TF | ? | ASPEED AST2600 | 1 | 6 |
| X12STL-IF | ? | ASPEED AST2600 | 2 | 4 | 1 | 3 |
| X12STL-F | ? | ASPEED AST2600 | 2 | 6 | 4 | 2 |
| X12DAi-N6 | ? | ASPEED AST2600 | 2 | 8 | 7 | 1 |
| X12DDW-A6 | ? | ASPEED AST2600 | 1 | 6 | 6 |
| X12DGO-6 | No |
| X12DGQ-R | No | ASPEED AST2600 |
| [X12DHM-6](https://www.supermicro.com/manuals/motherboard/X12/MNL-2296.pdf) | ? | ASPEED AST2600 | 2 | 10 | 8 | 2 |
| X12DPD-A6M25 | ? | ASPEED AST2600 | 1 | 6  | 6 |
| X12DPG-QR | ? | ASPEED AST2600 | 2 | 6 | 4 | 2 |
| X12DPG-AR | No |
| X12DPG-OA6 | No |
| X12DPFR-AN6 | ? | ASPEED AST2600 | 1 | 3 | 3 |
| [X12DPG-QT6](https://www.supermicro.com/manuals/motherboard/X12/MNL-2282.pdf) | ? | ASPEED AST2600 | 3 | 10 | 2 | 4 |
| X12DPG-U6 | No | ASPEED AST2600 |
| X12DPi-N6 | No |
| X12DPi-NT6 | No |
| X12DPL-NT6 | ? | ASPEED AST2600 | 2 | 8 | 6 | 2 |
| X12DPT-B6 | ? | ASPEED AST2600 | 1 | 2 | 2 | 0 |
| X12DPL-i6 | ? | ASPEED AST2600 | 2 | 8 | 6 | 2 |
| X12DPT-PT6 | ? | ASPEED AST2600 | 1 | 2 | 2 |
| X12DPT-PT46 | ? | ASPEED AST2600 | 1 | 2 | 2 |
| X12DPU-6 | ? | ASPEED AST2600 | 1 | 8 | 8 |
| X12DSC-6 | No |
| X12DSC-A6 | No |
| X12QCH+ | No |
| X12SAE-5 | No |
| X12SAE-5F | No |
| X12SCA-F | No |
| X12SCQ | No |
| X12SCV-LVDS | No |
| X12SCV-W | No |
| X12SCZ-F | ? | ASPEED AST2500 | 2 | 6 | 4 | 2 |
| X12SCZ-QF | ? | ASPEED AST2500 | 2 | 6 | 4 | 2 |
| X12SCZ-TLN4F | ? | ASPEED AST2500 | 2 | 6 | 4 | 2 |
| X12SPG-NF | ? | ASPEED AST2500 | 1 | 2 | 2 |
| X12SPA-TF | ? | ASPEED AST2500 | 2 | 10 | 6 | 4 |
| X12SPi-TF | Yes | ASPEED AST2600 | 2 | 7 | 5 | 2 |
| X12SPL-F | ? | ASPEED AST2600 | 2 | 7 | 5 | 2 |
| X12SPL-LN4F | ? | ASPEED AST2600 | 2 | 7 | 5 | 2 |
| X12SPM-LN6TF | ? | ASPEED AST2600 | 2 | 5 | 4 | 1 |
| X12SPM-TF | ? | ASPEED AST2600 | 2 | 5 | 4 | 1 |
| X12SPO-F | ? | ASPEED AST2600 | 2 | 7 | 5 | 2 |
| X12SPO-NTF | ? | ASPEED AST2600 | 2 | 7 | 5 | 2 |
| X12SPW-F | ? | ASPEED AST2600 | 1 | 7 | 7 |
| X12SPW-TF | ? | ASPEED AST2600 | 1 | 7 | 7 |
| X12SPZ-LN4F | ? | No |
| X12SPZ-SPLN6F | ? | No | 
| X12STD-F | No | ASPEED AST2600 |
| X12STE-F | No | 
| X12STH-F | ? | ASPEED AST2600 | 2 | 6 | 4 | 2 |
| X12STH-LN4F | ? | ASPEED AST2600 | 2 | 6 | 4 | 2 |
| X12STH-SYS | ? | ASPEED AST2600 | 2 | 6 | 4 | 2 |
| X12STL-F | ? | ASPEED AST2600 | 2 | 6 | 4 | 2 |
| X12STL-IF | ? | ASPEED AST2600 | 2 | 4 | 3 | 1 |
| X12STW-F | ? | ASPEED AST2600 | 1 | 6 | 6 |
| X12STW-TF | ? | ASPEED AST2600 | 1 | 6 | 6 |
| X12SPT-PT | ? | ASPEED AST2600 | 1 | 2 | 2 |
| X12SPT-GC | ? | ASPEED AST2600 | 1 | 1 | 1 |
| X12SPT-G | ? | ASPEED AST2600 | 1 | 1 | 1 |
| X12SPED-F | ? | ASPEED AST2600 | 1 | 4 | 4 |

## X13 Motherboards
| Model | Manual Fan<br>Control? | BMC | # Fan Zones | # Fan Headers | Zone 0<br>Fans | Zone 1<br>Fans |
| ----- |:---------------:| --- |:-----------:|:-------------:|:------:|:------:|
| X13SCA-F | ? | ASPEED AST2600 |
| X13SAE | Yes | ASPEED AST2600 | 2 | 5 | 2 | 3 |
| X13SAE-F <sup>5, 6</sup> | Yes | ASPEED AST2600 | 2 | 5 | 2 | 3 |

<sup>1</sup> Not compatible with IPMI. Requires custom programming with i2C.<br>
<sup>2</sup> May possibly work with X9 fan control protocol.<br>
<sup>3</sup> Fans can only be controlled via BIOS.<br>
<sup>4</sup> FANA is for add-on card and is controlled by system temperature settings in BIOS only<br>
<sup>5</sup> X13SAE-F may support only LCR and LNR [fan speed thresholds](/documentation/bmc-and-server-architecture/bmc-fan-speed-thresholds.md) (it does not appear to support LNC or UNC).<br>
<sup>6</sup> Appears to have an unusual fan hysteresis of 140.<br>
