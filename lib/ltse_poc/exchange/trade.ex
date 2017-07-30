defmodule LtsePoc.Exchange.Trade do
  use Ecto.Schema
  import Ecto.Changeset
  alias LtsePoc.Exchange.Trade


  schema "trades" do
    field :email, :string
    field :price, :float
    field :stock, :integer
    field :volume, :integer

    timestamps()
  end

  @doc false
  def changeset(%Trade{} = trade, attrs) do
    trade
    |> cast(attrs, [:email, :stock, :volume, :price])
    |> validate_required([:email, :stock, :volume, :price])
    |> unique_constraint(:email)
  end
end
