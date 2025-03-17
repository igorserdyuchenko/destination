connection: "your_connection_name"

view: sales_data {
  sql_table_name: sales_data.csv ;;

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
    sql: ${TABLE}.Sales ;;
    type: sum
  }

  measure: quantity {
    sql: ${TABLE}.Quantity ;;
    type: sum
  }
}

explore: sales_data {
  label: "Sales Data"
}