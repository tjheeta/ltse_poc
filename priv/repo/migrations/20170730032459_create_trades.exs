defmodule LtsePoc.Repo.Migrations.CreateTrades do
  use Ecto.Migration

  def change do
    create table(:trades) do
      add :email, :string
      add :stock, :integer
      add :volume, :integer
      add :price, :float

      timestamps()
    end

    create unique_index(:trades, [:email])
  end
end
