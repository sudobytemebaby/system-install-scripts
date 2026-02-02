# Arch Linux Btrfs Partitioner

## Запуск скрипта

в Live-окружении выполнить эти команды:

### 1. Скачать скрипт

```bash
curl -L https://raw.githubusercontent.com/sudobytemebaby/system-install-scripts/refs/heads/main/apply-partitions-btrfs.sh -o p.sh

```

### 2. Запусти установку

Скрипт интерактивно спросит, какой диск использовать (например, `/dev/nvme0n1`), и попросит подтверждение.

```bash
bash p.sh

```

---

- Создаст таблицу разделов **GPT**.
- Разметит **512MB EFI** и всё остальное под **Btrfs**.
- Создаст подтома: `@`, `@home`, `@log`, `@pkg`, `@tmp`, `@snapshots`.
- Примонтирует их в `/mnt` с опциями `zstd:3` и `discard=async`.
