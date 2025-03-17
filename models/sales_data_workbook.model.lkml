connection: "your_connection_name" {
  # Define your connection details here
}

include: "sales_data.view.lkml"

explore: sales_data {
  join: sales_data {
    type: left_outer
    sql_on: ${sales_data.OrderID} = ${sales_data.OrderID} ;;
  }
}

view: sales_data {
  sql_table_name: sales_data ;;

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