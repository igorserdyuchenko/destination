connection: "your_connection_name"

view: sales_data {
  sql_table_name: sales_data ;;

  dimension: order_id {
    type: number
    sql: ${TABLE}.OrderID ;;
  }

  dimension: date {
    type: date
    sql: ${TABLE}.Date ;;
  }

  dimension: category {
    type: string
    sql: ${TABLE}.Category ;;
  }

  dimension: product {
    type: string
    sql: ${TABLE}.Product ;;
  }

  measure: sales {
    type: sum
    sql: ${TABLE}.Sales ;;
  }

  measure: quantity {
    type: sum
    sql: ${TABLE}.Quantity ;;
  }
}

explore: sales_data {
  view_name: sales_data
}