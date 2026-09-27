# RV32I 5-stage pipeline

Учебный проект простого RISC-V конвейера на SystemVerilog. Цель — практика проектирования цифровых систем, моделирования, AXI4, конвейеризации, forwarding, hazard detection и branch prediction.

Проект реализует базовое подмножество RV32I. Данные и инструкции разделены: инструкции читаются из простой памяти инструкций, данные ходят через AXI4-совместимый интерфейс к простому slave-памяти.

## Основные возможности

- 5-стадийный конвейер: IF, ID, EX, MEM, WB.
- Раздельные instruction memory и data memory.
- AXI4 master/slave для данных.
- Forwarding из EX/MEM и MEM/WB.
- Hazard detection для load-use.
- Branch predictor: BTB + 2-bit PHT.
- Flush при неверном предсказании перехода.
- Stall при load-use и при работе с памятью.
- Простая модель памяти инструкций `l1i_top`.
- Тестовые программы для branch, jal, load/store, циклов while и do-while.

## Структура проекта

```
    .
    ├── build/                  результаты сборки и симуляции
    ├── data/                   примеры .mem и .s
    ├── rtl/
    │   ├── axi4/               AXI4 master/slave и обвязка
    │   ├── headers/            package, interface, decoder functions
    │   └── src/
    │       ├── branch_predictor/
    │       ├── core/
    │       ├── decode/
    │       ├── execute/
    │       ├── fetch/
    │       ├── memory/
    │       └── writeback/
    ├── tb/                     testbench
    ├── tests/                  ассемблерные тесты и ожидаемые результаты
    └── Makefile
```

## Реализованные инструкции

| Формат | Инструкции | Статус |
|---|---|---|
| R | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` | реализовано |
| I (OP-IMM) | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI` | реализовано |
| I (LOAD) | `LB`, `LH`, `LW`, `LBU`, `LHU` | реализовано |
| I (JALR) | `JALR` | реализовано |
| S | `SB`, `SH`, `SW` | реализовано |
| B | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` | реализовано |
| U | `LUI`, `AUIPC` | реализовано |
| J | `JAL` | реализовано |
| SYSTEM | `ECALL`, `EBREAK`, `CSRRW`, `CSRRS`, `CSRRC`, `CSRRWI`, `CSRRSI`, `CSRRCI` | декодируется, но полноценная обработка CSR/ECALL/EBREAK в execute/memory/writeback не завершена |

Не реализованы: `FENCE`, атомарные операции, `MUL/DIV`, floating point, compressed-инструкции, привилегированные режимы, исключения, MMU, кэши данных.

## Микроархитектура

### Конвейер

Используется интерфейс `pipeline_if` с modport-ами:

- `fetch`
- `decode`
- `execute`
- `memory`
- `writeback`
- `regfile`
- `memory_map`
- `hazard_unit`
- `branch_predictor`

Стадии:

1. IF — выборка инструкции.
2. ID — декодирование, чтение регистров, генерация управляющих сигналов.
3. EX — ALU, вычисление адресов переходов, проверка условий branch.
4. MEM — доступ к памяти данных через AXI4.
5. WB — запись результата в регистровый файл.

### Fetch

Модули: `fetch_top`, `l1i_top`.

- `pc` хранится в `fetch_top`.
- `l1i_top` — простая память инструкций на массиве.
- Адрес следующей инструкции: `pc + 4`, если нет branch/jump.
- При `flush` и `branch_taken` PC загружается из `pc_target`.
- При предсказании перехода PC может быть загружен из `pred_target`.
- В IF/ID latch попадают `instr_if_id`, `pc_if_id`, `valid_if_id`, признаки предсказания.

### Decode

Модули: `decode_top`, `decoder_funcs.svh`, `riscv_pkg.svh`.

- По opcode выбирается формат инструкции.
- Функции `decode_fmt_r`, `decode_fmt_i`, `decode_fmt_s`, `decode_fmt_b`, `decode_fmt_u`, `decode_fmt_j` заполняют `decoded_instr_t`.
- Формируются:
  - `alu_op`
  - `mem_sz_type`
  - `branch_cond`
  - `sys_op`
  - флаги `is_alu`, `is_load`, `is_store`, `is_branch`, `is_jump`, `is_system`
  - `reg_write`, `use_rs1`, `use_rs2`, `use_imm`, `use_pc`
- В ID/EX latch попадают `dec_id_ex`, `pc_id_ex`, `valid_id_ex`, `pred_taken_id_ex`, `pred_target_id_ex`.
- Здесь же реализованы forwarding-муксы для `rs1_data_id_ex` и `rs2_data_id_ex`.
- Приоритет forwarding: EX > MEM > WB.

### Execute

Модули: `execute_top`, `alu_top`, `count_pc_target`.

- `alu_top` выполняет арифметику и логику.
- Для `JAL` и `JALR` ALU формирует `pc + 4` как значение для записи в `rd`.
- Для `AUIPC` используется `pc + imm`.
- Для `LOAD` и `STORE` ALU считает адрес: `rs1 + imm`.
- `count_pc_target` вычисляет `pc_target` и `branch_taken`.
- Branch-условия: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`.
- В EX/MEM latch попадают:
  - `alu_result_ex_mem`
  - `rs2_data_ex_mem`
  - `rd_ex_mem`
  - `is_load_ex_mem`
  - `is_store_ex_mem`
  - `reg_write_ex_mem`
  - `mem_req_type`
  - `valid_ex_mem`

### Memory

Модули: `memory_top`, `memory_map`, `axi4_master`, `axi4_slave`.

- `memory_top` содержит FSM для load/store.
- `mem_stall` останавливает конвейер, пока память занята.
- `memory_map` преобразует внутренний запрос в AXI4-транзакцию.
- Поддерживаются размеры:
  - `LOAD_LB`, `LOAD_LH`, `LOAD_LW`, `LOAD_LBU`, `LOAD_LHU`
  - `STORE_SB`, `STORE_SH`, `STORE_SW`
- Выполняется sign/zero extension для load.
- Проверяется корректность адреса.
- `mem_resp_error` может принимать `NO_ERROR`, `ADDR_ERROR`, `UNKNOWN_MEM_SIZE`.
- AXI4 master поддерживает очередь запросов, outstanding-транзакции и burst-режим.
- AXI4 slave — простая память.
- В текущей конфигурации `memory_map` выставляет `read_len = 0` и `write_len = 0`, то есть фактически single-beat.

### Writeback

Модуль: `writeback_top`.

- Формирует `rd_addr_wb`, `rd_data_wb`, `rd_w_ena_wb`.
- Для load-инструкций в `rd` пишется `mem_read_data_mem_wb`.
- Для остальных — `alu_result_mem_wb`.
- Формирует WB-forwarding-сигналы `rs1_forward_wb`, `rs2_forward_wb`.

### Register file

Модуль: `register_file`.

- 32 регистра по 32 бита.
- Регистр `x0` всегда читается как 0.
- Запись в `x0` игнорируется.
- Два асинхронных порта чтения, один синхронный порт записи.

### Hazard detection

Модуль: `hazard_detection_unit`.

- Обнаруживает load-use hazard.
- Если инструкция в EX является load и её `rd` совпадает с `rs1` или `rs2` инструкции в ID, выставляется `stall`.
- `stall` останавливает IF и ID.

### Forwarding

Forwarding реализован в двух местах:

- В `decode_top` — для захвата `rs1_data_id_ex` и `rs2_data_id_ex`.
- В `writeback_top` — для формирования WB-forwarding.
- В `memory_top` — для MEM-forwarding.

Приоритет:

1. EX/MEM forwarding.
2. MEM/WB forwarding.
3. WB forwarding.
4. Значение из register file.

### Branch predictor

Модуль: `branch_predictor_top`.

- BTB на `BTB_SIZE` записей.
- В записи хранятся: `valid`, `tag`, `target`, `pht`.
- PHT — 2-битный счётчик: `SNT`, `WNT`, `WT`, `ST`.
- Предсказание taken, если `pht[1] == 1`.
- Обновление на стадии EX при `update_valid`.
- При неверном предсказании формируется `flush`.
- Flush сбрасывает неверно выбранные инструкции.

## Ограничения

- Нет полноценных исключений и прерываний.
- Нет CSRs в execute/memory/writeback.
- `ECALL` и `EBREAK` только декодируются.
- Нет `FENCE`.
- Нет атомарных операций.
- Нет `MUL`, `DIV`, `REM`.
- Нет floating point.
- Нет compressed-инструкций.
- Нет MMU.
- Нет кэшей данных.
- `l1i_top` — очень простая память инструкций без кэш-политик.
- AXI4 master умеет burst, но `memory_map` использует single-beat.
- Нет точных исключений и отката конвейера.

## Тесты

В `tests/` лежат тестовые программы:

- `branch_tests`
- `jal_tests`
- `load_store_tests`
- `loop_do_while_tests`
- `loop_while_tests`

В каждой директории есть:

- `instr_file.s` — ассемблер.
- `expect.txt` — ожидаемое состояние.

## Сборка и запуск

### Требования

- Verilator
- RISC-V GNU toolchain: `riscv64-elf-as`, `riscv64-elf-ld`, `riscv64-elf-objdump`

### Основные команды

```bash
    make all          # сборка симулятора для data/instr_file.s
    make sim          # то же самое
    make run          # сборка и запуск симулятора
    make data         # сгенерировать data/instr_file.mem из data/instr_file.s
    make disasm       # дизассемблировать data/instr_file.elf
    make view-mem     # показать data/instr_file.mem
    make lint         # запустить Verilator в режиме линта
    make clean        # удалить build/, obj_dir/, VCD-файлы и артефакты
```

### Тесты

Список тестов: `branch_tests`, `jal_tests`, `load_store_tests`, `loop_while_tests`, `loop_do_while_tests`.

Для каждого теста доступны цели:

```bash
    make data-<test>      # собрать <test>/instr_file.mem
    make sim-<test>       # собрать симулятор для теста
    make run-<test>       # собрать и запустить тест
    make disasm-<test>    # дизассемблировать тест
    make clean-<test>     # удалить артефакты теста
```

Пример:

```bash
    make run-branch_tests
```

Запустить все тесты:

```bash
    make test-all
```
