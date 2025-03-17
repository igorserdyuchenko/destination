connection: "your_connection_name" {
  # Define your connection details here
}

include: "sales_data.view.lkml"

explore: sales_data {
  view_name: sales_data

  # Define joins if necessary
}

view: sales_data {
  sql_table_name: sales_data ;;

  dimension: order_id {
    sql: ${TABLE}.OrderID ;;
    type: number
  }

  dimension: date {
    sql: ${TABLE}.Date ;;
    type: date
  }

  dimension: category {
    sql: ${TABLE}.Category ;;
    type: string
  }

  dimension: product {
    sql: ${TABLE}.Product ;;
    type: string
  }

  measure: sales {
    sql: SUM(${TABLE}.Sales) ;;
    type: sum
  }

  measure: quantity {
    sql: SUM(${TABLE}.Quantity) ;;
    type: sum
  }
}