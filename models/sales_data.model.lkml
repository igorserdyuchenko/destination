model: sales_data {
  connection: "your_connection_name"

  include: "*.view"

  explore: sales_data {
    join: sales_data_extract {
      type: left_outer
      sql_on: ${sales_data.OrderID} = ${sales_data_extract.OrderID} ;;
      relationship: many_to_one
    }
  }
}

view: sales_data {
  sql_table_name: sales_data.csv ;;

  dimension: OrderID {
    type: number
    sql: ${TABLE}.OrderID ;;
  }

  dimension: Date {
    type: date
    sql: ${TABLE}.Date ;;
  }

  dimension: Category {
    type: string
    sql: ${TABLE}.Category ;;
  }

  dimension: Product {
    type: string
    sql: ${TABLE}.Product ;;
  }

  measure: Sales {
    type: sum
    sql: ${TABLE}.Sales ;;
  }

  measure: Quantity {
    type: sum
    sql: ${TABLE}.Quantity ;;
  }
}

view: sales_data_extract {
  sql_table_name: Extract ;;

  dimension: OrderID {
    type: number
    sql: ${TABLE}.OrderID ;;
  }

  dimension: Date {
    type: date
    sql: ${TABLE}.Date ;;
  }

  dimension: Category {
    type: string
    sql: ${TABLE}.Category ;;
  }

  dimension: Product {
    type: string
    sql: ${TABLE}.Product ;;
  }

  measure: Sales {
    type: sum
    sql: ${TABLE}.Sales ;;
  }

  measure: Quantity {
    type: sum
    sql: ${TABLE}.Quantity ;;
  }
}