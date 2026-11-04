"""Prints what the dbt manifest records about the lineage of the lab number."""

import json
from pathlib import Path


class Manifesto:
    """Thin reader over target/manifest.json."""

    def __init__(self, caminho: Path) -> None:
        self._dados = json.loads(caminho.read_text(encoding="utf-8"))

    def pais(self, chave: str) -> list[str]:
        return sorted(self._dados["parent_map"].get(chave, []))

    def filhos(self, chave: str) -> list[str]:
        return sorted(self._dados["child_map"].get(chave, []))

    def imprimir(self) -> None:
        versao = self._dados["metadata"]["dbt_version"]
        print(f"dbt_version do manifesto: {versao}")
        for chave in (
            "model.linhagem.mart_faturamento_por_loja",
            "model.linhagem.stg_pedidos",
            "model.linhagem.copia_sem_ref",
            "model.linhagem.copia_da_view_do_sistema",
            "source.linhagem.sistema.vw_faturamento_itens",
            "exposure.linhagem.relatorio_faturamento_diretoria",
        ):
            print(f"pais de {chave}: {self.pais(chave)}")
        chave = "model.linhagem.mart_faturamento_por_loja"
        print(f"filhos de {chave}: {self.filhos(chave)}")

        modelo = self._dados["nodes"][chave]
        print(f"description do modelo: {modelo['description']!r}")
        print(f"meta do modelo: {modelo['config']['meta']}")
        print(f"description da coluna faturamento: {modelo['columns']['faturamento']['description']!r}")

        exposicao = self._dados["exposures"]["exposure.linhagem.relatorio_faturamento_diretoria"]
        print(f"exposure, tipo e dono: {exposicao['type']}, {exposicao['owner']['name']}")
        print(f"exposure, depends_on: {exposicao['depends_on']['nodes']}")


if __name__ == "__main__":
    Manifesto(Path("target/manifest.json")).imprimir()
