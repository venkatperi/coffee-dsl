catalog ->
  book (id : 'bk101'), ->
    author -> 'Gambardella, Matthew'
    title -> 'XML Developer\'s Guide'
    genre -> 'Computer'
    price ->
      MSRP -> '44.95'
      current -> '39.95'
    date (type: 'publish'), -> '2000-10-01'
    description -> 'An in-depth look at creating applications with XML.'

  book (id : 'bk102'), ->
    author -> 'Ralls, Kim'
    title -> 'Midnight Rain'
    genre -> 'Fantasy'
    price -> '5.95'
    publish_date -> '2000-12-16'
    description -> 'A former architect battles corporate zombies, an evil sorceress, and her own childhood to become queen of the world.'
