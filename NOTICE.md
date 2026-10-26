# 来源说明

## 许可范围

- 本仓库新增的 Dockerfile、Compose、脚本、文档：MIT，见 [LICENSE](LICENSE)。
- `server-2.5/` 下的 C 源码和 DATA：源自 [chenmingbiao/stone-age](https://github.com/chenmingbiao/stone-age)，上游未附许可证，按原样分发。其血统为 longzoro（龙王）2006 年的 2.5 商业代码，版权归原作者/原权利方。
- 客户端：华义国际 2.5 客户端，经 99ds 分发，著作权归原权利方。

## 本仓库的改动

- 新增 `linux/386` 容器构建（Debian buster 归档源、gnu89、MariaDB 头文件兼容）。
- 新增 Compose、DB 初始化、按容器角色拆分的入口脚本、备份恢复脚本。
- 新增开箱配置：服务器名、GM 账号、300 倍经验、出生资金和宠物。
- 安全修复：字符串截断补 NUL、格式串改为字面量、家族字段加长度上限。

其余逻辑与数据保持上游原样。

## 用途

学习和自用，不涉及商业运营。
